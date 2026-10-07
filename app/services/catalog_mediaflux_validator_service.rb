require 'csv'
require 'aws-sdk-s3'

class CatalogMediafluxValidatorService
  def initialize
    @s3 = Aws::S3::Client.new(region: 'ap-southeast-2')
  end

  def run
    inventory_csv = fetch_inventory_csv
    s3_files = extract_s3_files(inventory_csv)

    csv_key, csv_date = find_recent_mediaflux_csv
    mediaflux_files = fetch_mediaflux_files(csv_key)

    # Files uploaded on or after the mediaflux snapshot date can't be expected in it yet,
    # so ignore them until the next run. LastModifiedDate is ISO 8601, so string comparison works.
    cutoff = csv_date.iso8601

    missing = []
    size_mismatch = []
    ignored_too_new = 0
    ignored_changed = 0

    s3_files.each do |path, s3|
      if s3[:last_modified] >= cutoff
        ignored_too_new += 1
        next
      end
      next if mediaflux_files[path] == s3[:size]

      # The S3 inventory predates the mediaflux snapshot, so the object may have changed or gone since.
      live = live_object(path)
      if live.nil? || live.last_modified >= csv_date.to_time(:utc)
        ignored_changed += 1
      elsif !mediaflux_files.key?(path)
        missing << path
      elsif mediaflux_files[path] != live.content_length
        size_mismatch << { path:, s3_size: live.content_length, mediaflux_size: mediaflux_files[path] }
      end
    end

    Rails.logger.info "CatalogMediafluxValidator: ignored #{ignored_too_new} files uploaded on or after the mediaflux snapshot date of #{csv_date}"
    Rails.logger.info "CatalogMediafluxValidator: ignored #{ignored_changed} files changed or deleted in S3 since the S3 inventory"

    AdminMailer.with(missing:, size_mismatch:).catalog_mediaflux_report.deliver_now
  end

  private

  def live_object(path)
    @s3.head_object(bucket: 'nabu-catalog-prod', key: path)
  rescue Aws::S3::Errors::NotFound
    nil
  end

  def extract_s3_files(inventory_csv)
    s3_files = {}

    CSV.parse(inventory_csv, headers: false) do |row|
      _bucket_name, filename, _version_id, is_latest, delete_marker, size, last_modified, = row

      next if is_latest == 'false' || delete_marker == 'true'

      file = CGI.unescape(filename)

      raise "Duplicate file in S3 inventory: #{file}" if s3_files.key?(file)
      raise "Missing LastModifiedDate in S3 inventory for: #{file}" if last_modified.nil?

      s3_files[file] = { size: size.to_i, last_modified: }
    end

    s3_files
  end

  def fetch_mediaflux_files(csv_key)
    csv_content = @s3.get_object(bucket: 'nabu-meta-prod', key: csv_key).body.read

    mediaflux_prefix = 'asset:/projects/proj-1190_paradisec_backup-1128.4.248/paradisec/'
    files = {}

    CSV.parse(csv_content, headers: true) do |row|
      path = row['SRC_PATH']
      next unless path&.start_with?(mediaflux_prefix)

      relative_path = path.delete_prefix(mediaflux_prefix)
      files[relative_path] = row['SRC_LENGTH'].to_i
    end

    files
  end

  def find_recent_mediaflux_csv
    keys = []
    next_token = nil

    loop do
      response = @s3.list_objects_v2(
        bucket: 'nabu-meta-prod',
        prefix: 'mediaflux-inventory/',
        continuation_token: next_token
      )

      response.contents.each do |obj|
        keys << obj.key if obj.key.end_with?('.csv')
      end

      break unless response.is_truncated

      next_token = response.next_continuation_token
    end

    raise 'No mediaflux inventory CSV files found' if keys.empty?

    latest_key = keys.max

    # Check freshness - extract date from key like mediaflux-inventory/2026-03-18.csv
    match = latest_key.match(%r{mediaflux-inventory/(\d{4}-\d{2}-\d{2})\.csv})
    raise "Cannot parse date from mediaflux CSV key: #{latest_key}" unless match

    csv_date = Date.parse(match[1])
    raise "Mediaflux CSV is stale (#{csv_date}), must be within 2 days" if csv_date < Date.today - 2

    [latest_key, csv_date]
  end

  def fetch_inventory_csv
    reader = S3InventoryReader.new(@s3, 'nabu-meta-prod', 'inventories/catalog/nabu-catalog-prod/CatalogBucketInventory0/')
    run = reader.most_recent_run

    raise 'No S3 inventory directories found' if run.nil?
    raise "S3 inventory is stale (#{run.time}), must be within 7 days" if run.time < Time.now - 7.days

    reader.csv_for(run.key)
  end
end
