require 'oai'

module OAI::Provider::Response
  class RecordResponse < Base
    private
    # TODO Make this overidable upstream
    def identifier_for(record)
      "#{provider.prefix}:#{record.full_identifier}"
    end

    def timestamp_for(record)
      record.send(provider.model.timestamp_field.split('.').last).utc.xmlschema
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

module OAI::Provider
  class ActiveRecordWrapper
    def earliest
      earliest_obj = model.find(:first, :order => "#{timestamp_field} asc")
      earliest_obj.nil? ? Time.at(0) : earliest_obj.send(timestamp_field.split('.').last)
    end

    def latest
      latest_obj = model.find(:first, :order => "#{timestamp_field} desc")
      latest_obj.nil? ? Time.now : latest_obj.send(timestamp_field.split('.').last)
    end
  end
end

