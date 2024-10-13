require 'csv'
require 'aws-sdk-s3'

class CatalogReplicationValidatorService
  attr_reader :catalog_dir, :verbose

  def initialize
    # Strange bug in dev docker
    ENV.delete('AWS_SECRET_ACCESS_KEY')
    ENV.delete('AWS_ACCESS_KEY_ID')
    ENV.delete('AWS_SESSION_TOKEN')

    @s3 = Aws::S3::Client.new(region: 'ap-southeast-2')
  end

  def run
    prod_inventory = fetch_inventory_csv('prod')
    dr_inventory = fetch_inventory_csv('dr')

    prod_files, prod_new = extract_s3_files(prod_inventory)
    dr_files, dr_new = extract_s3_files(dr_inventory)

    prod_only = prod_files - dr_files - prod_new
    dr_only = dr_files - prod_files

    AdminMailer.with(prod_only:, dr_only:).catalog_replication_report.deliver_now
  end

  private

  def extract_s3_files(inventory_csv)
    s3_files = []
    new_files = []

    CSV.parse(inventory_csv, headers: false) do |row|
      _bucket_name, filename, _version_id, is_latest, delete_marker, _size, last_modified, _etag,
        storage_class,  multiple_upload,  multipart_upload_flag, replication_status, checksum_algo = row

      next if is_latest == 'false' || delete_marker == 'true'



      file = CGI.unescape(filename)

      s3_files << file

      # If the file was modifed in the last week add it to the new list
      new_files << file if Time.parse(last_modified) > Time.now - 1.week
    end

    s3_files = s3_files.reject { |filename| filename.ends_with?('pdsc_admin/ro-crate-metadata.json') }
      .reject { |filename| filename.starts_with?('pdsc_admin/') && filename.ends_with?('-deposit.pdf') }
      # TODO: Remove this after we migrate all the df files
      .reject { |filename| filename.ends_with?('df-PDSC_ADMIN.pdf') }

    if s3_files.size != s3_files.uniq.size
      raise 'Duplicate files in S3 inventory'
    end

    [s3_files, new_files]
  end

  def meta_bucket(env)
    env === 'prod' ? 'nabu-meta-prod' : 'nabu-metadr-prod'
  end

  def fetch_inventory_csv(env)
    inventory_dir = find_recent_inventory_dir(env)

    manifest_json = @s3.get_object(bucket: meta_bucket(env), key: "#{inventory_dir}manifest.json").body.read
    manifest = JSON.parse(manifest_json)

    files = manifest['files']
    if files.size > 1
      raise 'Multiple files in manifest'
    end

    file = files.first['key']

    # Download the S3 Inventory CSV file
    inventory_gzipped = @s3.get_object(bucket: meta_bucket(env), key: file).body.read
    inventory_csv = Zlib::GzipReader.new(StringIO.new(inventory_gzipped)).read
  end

  def find_recent_inventory_dir(env)
    inventory_files = fetch_inventory_files(env)

    # Extract the timestamp part from each key and convert it to Time object
    timestamped_files = inventory_files.map do |key|
      match = key.match(/(?:Catalog|Dr)BucketInventory0\/(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})Z/)
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

  def fetch_inventory_files(env)
    prefix = env === 'prod' ? 'inventories/catalog/nabu-catalog-prod/CatalogBucketInventory0/' : 'inventories/catalogdr/nabu-catalogdr-prod/DrBucketInventory0/'
    inventory_files = []
    next_token = nil

    loop do
      response = @s3.list_objects_v2(
        bucket: meta_bucket(env),
        prefix: prefix,
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
