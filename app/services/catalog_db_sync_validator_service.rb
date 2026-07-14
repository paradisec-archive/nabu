require 'csv'
require 'aws-sdk-s3'

class CatalogDbSyncValidatorService
  attr_reader :catalog_dir, :verbose

  def initialize(env)
    @bucket = "nabu-meta-#{env}"
    @catalog_bucket = "nabu-catalog-#{env}"
    @prefix = "inventories/catalog/nabu-catalog-#{env}/CatalogBucketInventory0/"

    # Strange bug in dev docker
    ENV.delete('AWS_SECRET_ACCESS_KEY')
    ENV.delete('AWS_ACCESS_KEY_ID')
    ENV.delete('AWS_SESSION_TOKEN')

    @s3 = Aws::S3::Client.new(region: 'ap-southeast-2')
  end

  def run
    reader = S3InventoryReader.new(@s3, @bucket, @prefix)
    inventory_csv = reader.csv_for(reader.most_recent_run.key)

    s3_files = extract_s3_files(inventory_csv)

    essence_files = Essence
      .includes(item: [:collection])
      .map(&:full_identifier)

    # The inventory is only generated daily, so recent uploads show up as db_only
    # and recent deletions as s3_only. Confirm each mismatch against S3 itself
    # before reporting it.
    db_only = (essence_files - s3_files).reject { |key| in_s3?(key) }
    s3_only = (s3_files - essence_files).select { |key| in_s3?(key) }

    AdminMailer.with(db_only:, s3_only:).catalog_s3_sync_report.deliver_now
  end

  private

  def in_s3?(key)
    @s3.head_object(bucket: @catalog_bucket, key:)

    true
  rescue Aws::S3::Errors::NotFound
    false
  end

  def extract_s3_files(inventory_csv)
    s3_files = []

    CSV.parse(inventory_csv, headers: false) do |row|
      _bucket_name, filename, _version_id, is_latest, delete_marker, _size, _last_modified, _etag,
        storage_class,  multiple_upload,  multipart_upload_flag, replication_status, checksum_algo = row

      next if is_latest == 'false' || delete_marker == 'true'

      s3_files << CGI.unescape(filename)
    end

    s3_files = s3_files.reject { |filename| Nabu::Catalog.instance.admin_key?(filename) }

    if s3_files.size != s3_files.uniq.size
      raise 'Duplicate files in S3 inventory'
    end

    s3_files
  end
end
