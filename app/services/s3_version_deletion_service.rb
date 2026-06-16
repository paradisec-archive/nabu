require 'csv'
require 'aws-sdk-s3'
require 'amazing_print'

# rubocop:disable Metrics/MethodLength,Metrics/BlockLength
class S3VersionDeletionService
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

    @count = Hash.new(0)
    @size = Hash.new(0)
    @remove_delete_markers = []
  end

  def run
    s3_files = get_s3_files

    s3_files.each_pair do |filename, versions|
      process_file(filename, versions)
    end

    ap @count
    @size.each do |key, size|
      @size[key] = size / 1024 / 1024 / 1024
    end
    ap @size

   # write the remove_delete_markers to a file
   file  = File.open('remove_delete_markers.txt', 'w')
   @remove_delete_markers.each do |version|
     file.puts version[:filename]
      puts version[:version_id] unless version[:version_id].empty?
   end
  end

  def process_file(filename, versions)
    if versions.size == 0
      p 'How can there be no versions for a file?'
      throw filename
    end

    if versions.size == 1
      version = versions.first
      throw version unless version[:is_latest]

      if version[:delete_marker]
        # We deleted files befire but forgot to kill the delete markers
        if version[:version_id].empty? && version[:size] == 0
          @count[:old_delete_marker] += 1
          @remove_delete_markers << version

          return
        end

        ap version
        throw 'WTF1'
      end

      @count[:single_upload] += 1
      @size[:single_upload] += version[:size]
      return
    end

    @count[:other] += 1
    @size[:other] += versions.map { |v| v[:size] }.sum

    latest = versions.last

    # ap versions
    # exit
    # #
    # if file[:is_latest] && !file[:delete_marker]
    #   @stats[:real] += 1
    #
    #   return
    # end
    #
    # if file[:is_latest] && file[:delete_marker]
    #   @stats[:deleted] += 1
    #
    #   return
    # end
    #
    # if !file[:is_latest] && file[:delete_marker]
    #   @stats[:deleted_version] += 1
    #
    #   return
    # end
    #
    # if !file[:is_latest] && !file[:delete_marker]
    #   @stats[:old_version] += 1
    #
    #   return
    # end
    #
    # raise "Unknown file state: #{file[:is_latest]} #{file[:delete_marker]}"
  end


  def get_s3_files
    reader = S3InventoryReader.new(@s3, @meta_bucket, @prefix)
    inventory_csv = reader.csv_for(reader.most_recent_run.key)

    extract_s3_files(inventory_csv)
  end

  def extract_s3_files(inventory_csv)
    s3_files = {}

    headers = %i[
      bucket_name filename version_id is_latest delete_marker size last_modified etag
        storage_class multiple_upload multipart_upload_flag replication_status checksum_algo
    ]

    versions = CSV.parse(inventory_csv, headers: false).map do |row|
      obj = headers.zip(row).to_h
      obj[:filename] = CGI.unescape(obj[:filename])
      obj[:size] = obj[:size].to_i
      obj[:is_latest] = obj[:is_latest] == 'true'
      obj[:delete_marker] = obj[:delete_marker] == 'true'

      obj
    end

    puts "We found #{versions.size} versions of files in the inventory"

    s3_files = Hash.new([])

    versions.each do |version|
      s3_files[version[:filename]] += [version]
    end

    s3_files.each do |_, versions|
      versions.sort_by! { |v| v[:last_modified] }
    end

    puts "We found #{s3_files.size} files in the inventory"

    s3_files
  end
end
# rubocop:enable Metrics/MethodLength,Metrics/BlockLength
