require 'csv'
require 'aws-sdk-s3'

# rubocop:disable Metrics/MethodLength,Metrics/BlockLength
class JunkService
  attr_reader :catalog_dir, :verbose

  def initialize(env, verbose: false)
    @meta_bucket = "nabu-meta-#{env}"
    @prefix = "inventories/catalog/nabu-catalog-#{env}/CatalogBucketInventory0/"
    @bucket = "nabu-catalog-#{env}"
    @verbose = verbose

    # Strange bug in dev docker
    ENV.delete('AWS_SECRET_ACCESS_KEY')
    ENV.delete('AWS_ACCESS_KEY_ID')
    ENV.delete('AWS_SESSION_TOKEN')

    @s3 = Aws::S3::Client.new(region: 'ap-southeast-2')
   end

  def run
    filenames = Essence.order(:filename).pluck(:filename, :mimetype)

    filenames.each do |filename, mimetype|
      essence_name, extension = filename.split('.', 2)

      next unless ['wav', 'mxf', 'mkv'].include?(extension)

      md = filename.match(/([A-Za-z0-9][a-zA-Z0-9_]+)-([A-Za-z0-9][a-zA-Z0-9_]+)-(.*)\.([^.]+)$/)
      collection = md[1]
      item = md[2]
      s3_path = "#{collection}/#{item}/#{filename}"

      begin
        head_resp = @s3.head_object({ bucket: @bucket, key: s3_path  })
      rescue Aws::S3::Errors::NotFound
        puts "#{s3_path} MISSING"
        next
      end

      content_type = head_resp.content_type
      mimetype_ok = content_type === mimetype || content_type === 'audio/x-wav'

      tag_resp = @s3.get_object_tagging({ bucket: @bucket, key: s3_path  })

      tags = tag_resp.tag_set.map { |tag| "#{tag.key}: #{tag.value}" }
      archive_ok = tags.include?('archive: true')

      next if archive_ok && mimetype_ok

      print "#{s3_path} A: #{archive_ok} "
      print "M: #{content_type} => #{mimetype} " unless mimetype_ok
      puts
    end
  end

  def get_s3_files
    reader = S3InventoryReader.new(@s3, @meta_bucket, @prefix)
    inventory_csv = reader.csv_for(reader.most_recent_run.key)
    extract_s3_files(inventory_csv)
  end

  def extract_s3_files(inventory_csv)
    s3_files = {}

    count = 0
    total = 0

    CSV.parse(inventory_csv, headers: false) do |row|
      bucket_name, filename, _version_id, is_latest, delete_marker, size, _last_modified, _etag,
        storage_class,  multiple_upload,  multipart_upload_flag, replication_status, checksum_algo = row

      next if is_latest == 'false' || delete_marker == 'true'

    if filename.match('wav$')
        total += size.to_i
      count += 1
    end

      s3_files[CGI.unescape(filename)] = { size: size }
    end

    p total
    p count
    s3_files
  end
end
# rubocop:enable Metrics/MethodLength,Metrics/BlockLength
