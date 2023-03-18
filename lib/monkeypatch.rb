require 'oai/provider'

# TODO: Send these patches upstream in some way

module OAI::Provider::Response
  class Base
    private

    # We need to convert the identifiers back to database IDs
    def extract_identifier(id)
      full_identifier = id.sub(/#{provider.prefix}:/, '')

      if full_identifier =~ /-/
        collection_identifier, item_identifier = full_identifier.split(/-/)
        collection = Collection.where(:identifier => collection_identifier).first

        item = collection.items.where(:identifier => item_identifier).first

        item.id
      else
        collection = Collection.where(:identifier => full_identifier).first

        collection.id
      end
    end
  end

  class RecordResponse < Base
    private
    # We don't want to use database ids for the identifier
    def identifier_for(record)
      "#{provider.prefix}:#{record.full_identifier}"
    end
  end
end
