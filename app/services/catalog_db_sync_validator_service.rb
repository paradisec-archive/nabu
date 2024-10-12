require 'csv'
require 'aws-sdk-s3'

class CatalogDbSyncValidatorService
  attr_reader :catalog_dir, :verbose

  def initialize(env)
    @bucket = "nabu-meta-#{env}"
    @prefix = "inventories/catalog/nabu-catalog-#{env}/CatalogBucketInventory0/"

    # Strange bug in dev docker
    ENV.delete('AWS_SECRET_ACCESS_KEY')
    ENV.delete('AWS_ACCESS_KEY_ID')
    ENV.delete('AWS_SESSION_TOKEN')

    @s3 = Aws::S3::Client.new(region: 'ap-southeast-2')
  end

  def run
    inventory_dir = find_recent_inventory_dir
    inventory_csv = fetch_inventory_csv(inventory_dir)

    s3_files = extract_s3_files(inventory_csv)

    essence_files = Essence
      .includes(item: [:collection])
      .map(&:full_identifier)

    db_only = essence_files - s3_files
    s3_only = s3_files - essence_files

    AdminMailer.with(db_only:, s3_only:).catalog_s3_sync_report.deliver_now
  end

  private

  def extract_s3_files(inventory_csv)
    s3_files = []

    CSV.parse(inventory_csv, headers: false) do |row|
      _bucket_name, filename, _version_id, is_latest, delete_marker, _size, _last_modified, _etag,
        storage_class,  multiple_upload,  multipart_upload_flag, replication_status, checksum_algo = row

      next if is_latest == 'false' || delete_marker == 'true'

      s3_files << CGI.unescape(filename)
    end

    s3_files = s3_files.reject { |filename| filename.ends_with?('pdsc_admin/ro-crate-metadata.json') }
      .reject { |filename| filename.starts_with?('pdsc_admin/') && filename.ends_with?('-deposit.pdf') }
      # TODO: Remove this after we migrate all the df files
      .reject { |filename| filename.ends_with?('df-PDSC_ADMIN.pdf') }

    if s3_files.size != s3_files.uniq.size
      raise 'Duplicate files in S3 inventory'
    end

    s3_files
  end

  def fetch_inventory_csv(inventory_dir)
    manifest_json = @s3.get_object(bucket: @bucket, key: "#{inventory_dir}manifest.json").body.read
    manifest = JSON.parse(manifest_json)

    files = manifest['files']
    if files.size > 1
      raise 'Multiple files in manifest'
    end

    file = files.first['key']

    # Download the S3 Inventory CSV file
    inventory_gzipped = @s3.get_object(bucket: @bucket, key: file).body.read
    inventory_csv = Zlib::GzipReader.new(StringIO.new(inventory_gzipped)).read
  end

  def find_recent_inventory_dir
    inventory_files = fetch_inventory_files

    # Extract the timestamp part from each key and convert it to Time object
    timestamped_files = inventory_files.map do |key|
      match = key.match(/CatalogBucketInventory0\/(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})Z/)
      if match
        year, month, day, hour, minute = match.captures
        time = Time.new(year, month, day, hour, minute)
        { key: key, time: time }
      end
    end.compact

    # Find the most recent file
    most_recent_dir = timestamped_files.max_by { |file| file[:time] }

    most_recent_dir[:key]
  end

  def fetch_inventory_files
    inventory_files = []
    next_token = nil

    loop do
      response = @s3.list_objects_v2(
        bucket: @bucket,
        prefix: @prefix,
        delimiter: '/',
        continuation_token: next_token
      )

      # Collect all object keys
      inventory_files += response.common_prefixes.map(&:prefix)

      break unless response.is_truncated

      next_token = response.next_continuation_token
    end

    inventory_files
  end
end
