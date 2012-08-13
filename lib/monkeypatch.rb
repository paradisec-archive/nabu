require 'oai'

module OAI::Provider::Response
  class RecordResponse < Base
    private
    # TODO Make this overidable upstream
    def identifier_for(record)
      "#{provider.prefix}:#{record.full_identifier}"
    end
  end

  class Base
    private
    def extract_identifier(id)
      Rails.logger.debug id
      full_identifier = id.sub(/#{provider.prefix}:/, '')
      if full_identifier =~ /-/
        collection_identifier, item_identifier = full_identifier.split /-/
        collection = Collection.where(:identifier => collection_identifier).first
        item = collection.items.where(:identifier => item_identifier).first
        item.id
      else
        collection = Collection.where(:identifier => full_identifier).first
        collection.id
      end
    end
  end
end

