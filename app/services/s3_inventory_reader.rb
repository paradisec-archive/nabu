require 'json'
require 'zlib'
require 'stringio'
require 'aws-sdk-s3'

# Reads AWS S3 Inventory reports for a bucket: locates the inventory runs under a
# given prefix, picks the most recent, and returns its CSV decompressed.
class S3InventoryReader
  Run = Data.define(:key, :time)

  def initialize(s3, bucket, prefix)
    @s3 = s3
    @bucket = bucket
    @prefix = prefix
  end

  # The most recent inventory run, or nil if none exist. Each run lives in a
  # timestamped directory, e.g. ".../CatalogBucketInventory0/2026-06-15T01-00Z/".
  def most_recent_run
    runs = list_run_dirs.filter_map do |key|
      match = key.match(/(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})Z/)
      next unless match

      Run.new(key:, time: Time.new(*match.captures))
    end

    runs.max_by(&:time)
  end

  # The decompressed CSV for a given run directory. S3 Inventory splits its output
  # into multiple gzipped CSV chunks once the bucket grows large enough, so download
  # every file listed in the manifest and concatenate them.
  def csv_for(run_dir)
    manifest_json = @s3.get_object(bucket: @bucket, key: "#{run_dir}manifest.json").body.read
    manifest = JSON.parse(manifest_json)

    manifest['files'].map do |file|
      gzipped = @s3.get_object(bucket: @bucket, key: file['key']).body.read
      Zlib::GzipReader.new(StringIO.new(gzipped)).read
    end.join
  end

  private

  def list_run_dirs
    run_dirs = []
    next_token = nil

    loop do
      response = @s3.list_objects_v2(
        bucket: @bucket,
        prefix: @prefix,
        delimiter: '/',
        continuation_token: next_token
      )

      run_dirs += response.common_prefixes.map(&:prefix)

      break unless response.is_truncated

      next_token = response.next_continuation_token
    end

    run_dirs
  end
end
