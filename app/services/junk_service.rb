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

  private

  def get_s3_files
    inventory_dir = find_recent_inventory_dir
    inventory_csv = fetch_inventory_csv(inventory_dir)
    s3_files = extract_s3_files(inventory_csv)
  end
  def extract_s3_files(inventory_csv)
    s3_files = []

    CSV.parse(inventory_csv, headers: false) do |row|
      p row
      bucket_name, filename, _version_id, is_latest, delete_marker, _size, _last_modified, _etag,
        storage_class,  multiple_upload,  multipart_upload_flag, replication_status, checksum_algo = row

      next if is_latest == 'false' || delete_marker == 'true'

      s3_files << CGI.unescape(filename)
      end

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
    puts "Downloading S3 Inventory CSV file: #{file}"
    inventory_gzipped = @s3.get_object(bucket: @bucket, key: file).body.read
    puts "Unzipping file: #{file}\n\n"
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

    puts "Most recent inventory file: #{most_recent_dir[:key]}"
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
# rubocop:enable Metrics/MethodLength,Metrics/BlockLength
