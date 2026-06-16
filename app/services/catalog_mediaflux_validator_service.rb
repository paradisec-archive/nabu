require 'csv'
require 'aws-sdk-s3'

class CatalogMediafluxValidatorService
  def initialize
    # Strange bug in dev docker
    ENV.delete('AWS_SECRET_ACCESS_KEY')
    ENV.delete('AWS_ACCESS_KEY_ID')
    ENV.delete('AWS_SESSION_TOKEN')

    @s3 = Aws::S3::Client.new(region: 'ap-southeast-2')
  end

  def run
    inventory_csv = fetch_inventory_csv
    s3_files = extract_s3_files(inventory_csv)

    mediaflux_files = fetch_mediaflux_files

    missing = []
    size_mismatch = []

    s3_files.each do |path, s3_size|
      if mediaflux_files.key?(path)
        if mediaflux_files[path] != s3_size
          size_mismatch << { path:, s3_size:, mediaflux_size: mediaflux_files[path] }
        end
      else
        missing << path
      end
    end

    AdminMailer.with(missing:, size_mismatch:).catalog_mediaflux_report.deliver_now
  end

  private

  def extract_s3_files(inventory_csv)
    s3_files = {}

    CSV.parse(inventory_csv, headers: false) do |row|
      _bucket_name, filename, _version_id, is_latest, delete_marker, size, = row

      next if is_latest == 'false' || delete_marker == 'true'

      file = CGI.unescape(filename)

      raise "Duplicate file in S3 inventory: #{file}" if s3_files.key?(file)

      s3_files[file] = size.to_i
    end

    s3_files
  end

  def fetch_mediaflux_files
    csv_key = find_recent_mediaflux_csv
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

    latest_key
  end

  def fetch_inventory_csv
    reader = S3InventoryReader.new(@s3, 'nabu-meta-prod', 'inventories/catalog/nabu-catalog-prod/CatalogBucketInventory0/')
    run = reader.most_recent_run

    raise 'No S3 inventory directories found' if run.nil?
    raise "S3 inventory is stale (#{run.time}), must be within 7 days" if run.time < Time.now - 7.days

    reader.csv_for(run.key)
  end
end
