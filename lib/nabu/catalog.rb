require 'singleton'

require 'aws-sdk-s3'

module Nabu
  class Catalog
    include Singleton

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
          endpoint: 'http://s3:9090',
          force_path_style: true
        )
      end

      @s3 = Aws::S3::Client.new(params)
      @presigner = Aws::S3::Presigner.new(client: @s3)
    end

    def delete_collection(collection)
      Rails.logger.debug { "Nabu::Catalog: Deleting collection #{collection.identifier}" }
      delete_by_prefix(collection.identifier)
    end

    def delete_item(item)
      Rails.logger.debug { "Nabu::Catalog: Deleting item #{item.full_identifier}" }
      parts = [item.collection.identifier, item.identifier]

      delete_by_prefix(parts.join('/'))
    end

    def delete_essence(essence)
      Rails.logger.debug { "Nabu::Catalog: Deleting essence #{essence.item.full_identifier}:#{essence.filename}" }
      parts = [essence.item.collection.identifier, essence.item.identifier, essence.filename]

      delete_by_prefix(parts.join('/'))
    end

    def upload_collection_admin(collection, filename, data, content_type)
      Rails.logger.debug { "Nabu::Catalog: Uploading collection admin file #{collection.identifier}:#{filename}" }
      parts = [collection.identifier, 'pdsc_admin', filename]

      upload(parts.join('/'), data, content_type)
    end

    def upload_item_admin(item, filename, data, content_type)
      Rails.logger.debug { "Nabu::Catalog: Uploading item admin file #{item.full_identifier}:#{filename}" }
      parts = [item.collection.identifier, item.identifier, 'pdsc_admin', filename]

      upload(parts.join('/'), data, content_type)
    end

    def collection_admin_url(collection, filename)
      Rails.logger.debug { "Nabu::Catalog: Downloading collection admin file #{collection.identifier}:#{filename}" }
      parts = [collection.identifier, 'pdsc_admin', filename]

      download(parts.join('/'))
    end

    def item_admin_url(item, filename)
      Rails.logger.debug { "Nabu::Catalog: Downloading item admin file #{item.full_identifier}:#{filename}" }
      parts = [item.collection.identifier, item.identifier, 'pdsc_admin', filename]

      download(parts.join('/'))
    end

    def essence_url(essence, as_attachment: false, filename:)
      Rails.logger.debug { "Nabu::Catalog: Get essence URL #{essence.item.full_identifier}:#{essence.filename}" }
      parts = [essence.item.collection.identifier, essence.item.identifier, essence.filename]

      download(parts.join('/'), as_attachment:, filename:)
    end

    def deposit_form_url(collection, as_attachment: false)
      filename = "#{collection.identifier}-deposit.pdf"
      Rails.logger.debug { "Nabu::Catalog: Get despoit form URL #{collection.identifier}:#{filename}" }
      parts = [collection.identifier, 'pdsc_admin', filename]

      download(parts.join('/'), as_attachment:)
    end

    private

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

    def download(key, as_attachment: false, filename:)
      disposition = nil
      if as_attachment
        disposition = 'attachment'
        disposition += "; filename=\"#{filename}\"" if filename
      end

      @presigner.presigned_url(
        :get_object,
        bucket: bucket_name,
        key:,
        response_content_disposition: disposition
      )
    end

    def delete_by_prefix(prefix)
      response = @s3.list_objects_v2(
        bucket: bucket_name,
        prefix:
      )

      keys = response.contents.map(&:key)
      if keys.empty?
        Rails.logger.debug { 'No files to delete' }
        return 0
      end

      Rails.logger.debug { "Deleting #{keys.join(',')} files" }

      throw "Too many files to delete: #{keys.size}" if keys.size > 50

      del_response = @s3.delete_objects(
        bucket: bucket_name,
        delete: {
          objects: keys.map { |key| { key: } },
          quiet: true
        }
      )

      return keys.size unless del_response.errors.any?

      throw "Error deleting files: #{del_response.errors}"
    end
  end
end
