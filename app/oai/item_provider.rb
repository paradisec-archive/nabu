require 'oai'

# Monkey patch
module OAI::Provider::Response
  class RecordResponse < Base
    private
    # TODO Make this overidable upstream
    def identifier_for(record)
      '#{provider.prefix}:#{record.full_identifier}'
    end
  end
end

module OAI::Provider::Metadata 
  class Olac < Format

    def initialize
      @prefix = 'olac'
      @schema = 'http://www.language-archives.org/OLAC/1.1/olac-archive.xsd'
      @namespace = 'http://www.language-archives.org/OLAC/1.1/'
      @element_namespace = 'olac'
    end

    def header_specification
      {
        'xmlns:oai_dc'  => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
        'xmlns:dc'      => 'http://purl.org/dc/elements/1.1/',
        'xmlns:xsi'     => 'http://www.w3.org/2001/XMLSchema-instance',
        'xmlns:dcterms' => 'http://purl.org/dc/terms/',
        'xmlns:olac'    => 'http://www.language-archives.org/OLAC/1.1/',
        'xsi:schemaLocation' => %{
          http://www.openarchives.org/OAI/2.0/oai_dc/
          http://www.openarchives.org/OAI/2.0/oai_dc.xsd
          http://www.language-archives.org/OLAC/1.1/dcterms.xsd
          http://www.language-archives.org/OLAC/1.1/
          http://www.language-archives.org/OLAC/1.1/olac.xsd
        }
      }
    end

  end
end
OAI::Provider::Base.register_format(OAI::Provider::Metadata::Olac.instance)

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
  sample_id 'AA1-001'
  source_model OAI::Provider::ActiveRecordWrapper.new(::Item, :limit => 100)
end
