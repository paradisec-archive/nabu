require 'singleton'

require 'aws-sdk-s3'

module Nabu
  class Catalog
    include Singleton

    ADMIN_ROCRATE_FILENAME = 'ro-crate-metadata.json'.freeze
    DEPOSIT_FORM_SUFFIX = '-deposit.pdf'.freeze
    DEPOSIT_FORM_KEY_PATTERN = %r{\A([^/]+)/\1#{Regexp.escape(DEPOSIT_FORM_SUFFIX)}\z}

    # S3's DeleteObjects API accepts at most 1000 keys per request.
    MAX_DELETE_KEYS = 1000

    def initialize
      params = {
        region: 'ap-southeast-2'
      }

      if Rails.env.development? || Rails.env.test?
        # s3 mock
        params.merge!(
          region: 'us-east-1',
          access_key_id: 'S3RVER',
          secret_access_key: 'S3RVER',
          endpoint: ENV.fetch('S3_ENDPOINT', 'http://s3:9090'),
          force_path_style: true
        )
      end

      @s3 = Aws::S3::Client.new(params)
      @presigner = Aws::S3::Presigner.new(client: @s3)
    end

    def essence_key(essence)
      [essence.item.collection.identifier, essence.item.identifier, essence.filename].join('/')
    end

    def item_rocrate_key(item)
      item_admin_key(item, ADMIN_ROCRATE_FILENAME)
    end

    def collection_rocrate_key(collection)
      collection_admin_key(collection, ADMIN_ROCRATE_FILENAME)
    end

    def deposit_form_key(collection)
      collection_admin_key(collection, "#{collection.identifier}#{DEPOSIT_FORM_SUFFIX}")
    end

    # True for the admin files nabu writes alongside essences: RO-Crate metadata
    # at the collection/item root and the collection's deposit PDF.
    def admin_key?(key)
      return true if key.end_with?("/#{ADMIN_ROCRATE_FILENAME}")

      key.end_with?(DEPOSIT_FORM_SUFFIX) && key.match?(DEPOSIT_FORM_KEY_PATTERN)
    end

    # Every key that makes up an item in the bucket: its essence files plus its admin metadata.
    def item_keys(item)
      keys = item.essences.map { |essence| essence_key(essence) }
      keys << item_rocrate_key(item)
      keys
    end

    # Every key that makes up a collection in the bucket: its items' keys plus its admin files.
    def collection_keys(collection)
      keys = collection.items.includes(:essences).flat_map { |item| item_keys(item) }
      keys << collection_rocrate_key(collection)
      keys << deposit_form_key(collection)
      keys
    end

    def item_prefix(item)
      "#{item.collection.identifier}/#{item.identifier}/"
    end

    def collection_prefix(collection)
      "#{collection.identifier}/"
    end

    # Deletes exactly the given keys — never a prefix. Missing keys are treated as
    # deleted by S3, so calling this twice with the same keys is safe.
    def delete_keys(keys)
      return 0 if keys.empty?
      raise ArgumentError, "delete_objects accepts at most #{MAX_DELETE_KEYS} keys, got #{keys.size}" if keys.size > MAX_DELETE_KEYS

      Rails.logger.debug { "Nabu::Catalog: Deleting keys #{keys.join(',')}" }

      response = @s3.delete_objects(
        bucket: bucket_name,
        delete: {
          objects: keys.map { |key| { key: } },
          quiet: true
        }
      )

      raise "Error deleting files: #{response.errors.map { |error| "#{error.key}: #{error.code}" }.join(', ')}" if response.errors.any?

      keys.size
    end

    def list_keys(prefix)
      prefix += '/' unless prefix.end_with?('/')

      @s3.list_objects_v2(bucket: bucket_name, prefix:).flat_map { |page| page.contents.map(&:key) }
    end

    def key_exists?(key)
      @s3.head_object(bucket: bucket_name, key:)

      true
    rescue Aws::S3::Errors::NotFound
      false
    end

    def copy_key(source_key, target_key)
      Rails.logger.debug { "Nabu::Catalog: Copying #{source_key} to #{target_key}" }

      @s3.copy_object(
        bucket: bucket_name,
        copy_source: "/#{bucket_name}/#{source_key}",
        key: target_key
      )
    end

    def upload_collection_admin(collection, filename, data, content_type)
      Rails.logger.debug { "Nabu::Catalog: Uploading collection admin file #{collection.identifier}:#{filename}" }

      upload(collection_admin_key(collection, filename), data, content_type)
    end

    def upload_item_admin(item, filename, data, content_type)
      Rails.logger.debug { "Nabu::Catalog: Uploading item admin file #{item.full_identifier}:#{filename}" }

      upload(item_admin_key(item, filename), data, content_type)
    end

    def collection_admin_url(collection, filename)
      Rails.logger.debug { "Nabu::Catalog: Downloading collection admin file #{collection.identifier}:#{filename}" }

      download(collection_admin_key(collection, filename))
    end

    def item_admin_url(item, filename)
      Rails.logger.debug { "Nabu::Catalog: Downloading item admin file #{item.full_identifier}:#{filename}" }

      download(item_admin_key(item, filename))
    end

    def essence_url(essence, as_attachment: false, filename: nil)
      Rails.logger.debug { "Nabu::Catalog: Get essence URL #{essence.item.full_identifier}:#{essence.filename}" }

      download(essence_key(essence), as_attachment:, filename:)
    end

    def deposit_form_url(collection, as_attachment: false)
      Rails.logger.debug { "Nabu::Catalog: Get deposit form URL #{collection.identifier}" }

      download(deposit_form_key(collection), as_attachment:)
    end

    private

    def collection_admin_key(collection, filename)
      [collection.identifier, filename].join('/')
    end

    def item_admin_key(item, filename)
      [item.collection.identifier, item.identifier, filename].join('/')
    end

    def bucket_name
      @bucket_name ||= Rails.configuration.catalog_bucket
    end

    def upload(key, data, content_type)
      @s3.put_object(
        bucket: bucket_name,
        key:,
        body: data,
        content_type:
      )
    end

    def download(key, as_attachment: false, filename: nil)
      disposition = nil
      if as_attachment
        disposition = 'attachment'
        disposition += "; filename=\"#{filename}\"" if filename
      end

      @presigner.presigned_url(
        :get_object,
        expires_in: 3600 * 24 * 7,
        bucket: bucket_name,
        key:,
        response_content_disposition: disposition
      )
    end
  end
end
