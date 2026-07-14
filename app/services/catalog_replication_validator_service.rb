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

    s3_files = s3_files.reject { |filename| filename.ends_with?('/ro-crate-metadata.json') }
      .reject { |filename| filename.match?(%r{\A([^/]+)/\1-deposit\.pdf\z}) }

    if s3_files.size != s3_files.uniq.size
      raise 'Duplicate files in S3 inventory'
    end

    [s3_files, new_files]
  end

  def meta_bucket(env)
    env === 'prod' ? 'nabu-meta-prod' : 'nabu-metadr-prod'
  end

  def fetch_inventory_csv(env)
    reader = S3InventoryReader.new(@s3, meta_bucket(env), inventory_prefix(env))
    reader.csv_for(reader.most_recent_run.key)
  end

  def inventory_prefix(env)
    if env === 'prod'
      'inventories/catalog/nabu-catalog-prod/CatalogBucketInventory0/'
    else
      'inventories/catalogdr/nabu-catalogdr-prod/DrBucketInventory0/'
    end
  end
end
