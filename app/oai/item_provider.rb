require 'oai'

# Monkey patch
module OAI::Provider::Response
  class RecordResponse < Base
    private
    # TODO Make this overidable upstream
    def identifier_for(record)
      "#{provider.prefix}:#{record.full_identifier}"
    end
  end
end

module OAI::Provider::Response
  class Base
    private
    def extract_identifier(id)
      full_identifier = id.sub(/#{provider.prefix}:/, '')
      collection_identifier, item_identifier = full_identifier.split /-/
      collection = Collection.where(:identifier => collection_identifier).first
      item = collection.items.where(:identifier => item_identifier).first
      item.id
    end
  end
end

class ItemProvider < OAI::Provider::Base
  repository_name 'Pacific And Regional Archive for Digital Sources in Endangered Cultures (PARADISEC)'
  repository_url 'http://paradisec.org.au/oai/collection'
  record_prefix 'oai:paradisec.org.au'
  admin_email 'nicholas.thieberger@paradisec.org.au'
  source_model OAI::Provider::ActiveRecordWrapper.new(::Item, :limit => 100)
end
