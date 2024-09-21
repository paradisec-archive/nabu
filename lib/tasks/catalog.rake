require 'csv'
require 'aws-sdk-s3'

# Strange bug in dev docker
ENV.delete('AWS_SECRET_ACCESS_KEY')
ENV.delete('AWS_ACCESS_KEY_ID')
ENV.delete('AWS_SESSION_TOKEN')

S3_CLIENT = Aws::S3::Client.new(region: 'ap-southeast-2')

def find_recent_inventory_dir(inventory_bucket, inventory_prefix)
  inventory_files = []
  next_token = nil

  loop do
    response = S3_CLIENT.list_objects_v2(
      bucket: inventory_bucket,
      prefix: inventory_prefix,
      delimiter: '/',
      continuation_token: next_token
    )

    # Collect all object keys
    inventory_files += response.common_prefixes.map(&:prefix)

    break unless response.is_truncated

    next_token = response.next_continuation_token
  end

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

namespace :catalog do
  desc 'Compare files in the essence table with the S3 inventory and find differences'
  task s3_db_diff: :environment do
    env = ENV.fetch('AWS_PROFILE').sub('nabu-', '')

    inventory_bucket = "nabu-meta-#{env}"
    inventory_prefix = "inventories/catalog/nabu-catalog-#{env}/CatalogBucketInventory0/"

    inventory_dir = find_recent_inventory_dir(inventory_bucket, inventory_prefix)

    manifest_json = S3_CLIENT.get_object(bucket: inventory_bucket, key: "#{inventory_dir}manifest.json").body.read
    manifest = JSON.parse(manifest_json)

    files = manifest['files']
    if files.size > 1
      raise 'Multiple files in manifest'
    end

    file = files.first['key']

    # Download the S3 Inventory CSV file
    puts "Downloading S3 Inventory CSV file: #{file}"
    inventory_gzipped = S3_CLIENT.get_object(bucket: inventory_bucket, key: file).body.read
    puts "Unzipping file: #{file}\n\n"
    inventory_csv = Zlib::GzipReader.new(StringIO.new(inventory_gzipped)).read

    s3_files = []
    CSV.parse(inventory_csv, headers: false) do |row|
      _bucket_name, filename, _version_id, is_latest, delete_marker, _size, _last_modified, _etag,
        storage_class,  multiple_upload,  multipart_upload_flag, replication_status, checksum_algo = row

      next if is_latest == 'false' || delete_marker == 'true'

      s3_files << CGI.unescape(filename)
    end

    s3_files
      .reject! { |filename| filename.end_with?('pdsc_admin/ro-crate-metadata.json') }
      .reject! { |filename| filename.end_with?('-CAT-PDSC_ADMIN.xml') }
      .reject! { |filename| filename.end_with?('checksum-PDSC_ADMIN.txt') }
      .reject! { |filename| filename.end_with?('df-PDSC_ADMIN.pdf') }
      .reject! { |filename| filename.end_with?('df2-PDSC_ADMIN.pdf') }
      .reject! { |filename| filename.end_with?('df-PDSC_ADMIN.rtf') }
      .reject! { |filename| filename.end_with?('df_revised-PDSC_ADMIN.pdf') }
      .reject! { |filename| filename.end_with?('df_ammended-PDSC_ADMIN.pdf') }
      # Do we still need these?
      .reject! { |filename| filename.end_with?('thumb-PDSC_ADMIN.jpg') }

    if s3_files.size != s3_files.uniq.size
      raise 'Duplicate files in S3 inventory'
    end

    essence_files = Essence
      .includes(item: [:collection])
      .map(&:full_identifier)

    missing_in_s3 = essence_files - s3_files
    missing_in_db = s3_files - essence_files

    puts "Files in database but missing from S3:\n -#{missing_in_s3[0, 100].join("\n")}"
    puts
    puts
    puts "Files in S3 but missing from database:\n +#{missing_in_db[0, 100].join("\n")}"
  end

  # desc 'Delete all PDSC files from S3 bucket'
  # task delete_cat_pdsc_admin_xml: :environment do
  #   bucket_name = 'nabu-catalog-prod'
  #
  #   puts "Deleting pdsc_admin files from bucket: #{bucket_name}"
  #
  #   continuation_token = nil
  #   objects_to_delete = []
  #   total = 0
  #
  #   loop do
  #     response = S3_CLIENT.list_objects_v2(
  #       bucket: bucket_name,
  #       continuation_token: continuation_token
  #     )
  #     total += response.contents.size
  #
  #     response.contents.each do |object|
  #       if object.key.end_with?('CAT-PDSC_ADMIN.xml') or object.key.end_with?('checksum-PDSC_ADMIN.txt') or object.key.end_with?('thumb-PDSC_ADMIN.jpg')
  #         objects_to_delete << { key: object.key }
  #       end
  #
  #       if objects_to_delete.size == 1000
  #         delete_objects(bucket_name, objects_to_delete)
  #         objects_to_delete.clear
  #       end
  #     end
  #
  #     break unless response.is_truncated
  #
  #     continuation_token = response.next_continuation_token
  #     puts "#{total} objects processed"
  #   end
  #
  #   # Delete any remaining objects
  #   delete_objects(bucket_name, objects_to_delete) unless objects_to_delete.empty?
  #
  #   puts 'Finished deleting PDSC files'
  #   puts "Total objects: #{total}"
  # end
  #
  # def delete_objects(bucket_name, objects)
  #   response = S3_CLIENT.delete_objects(
  #     bucket: bucket_name,
  #     delete: { objects: objects }
  #   )
  #   puts "Deleted #{response.deleted.size} objects"
  #   puts "Errors: #{response.errors.size}" if response.errors.any?
  # end
end
