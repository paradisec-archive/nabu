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
          http://purl.org/dc/elements/1.1/
          http://dublincore.org/schemas/xmls/qdc/2006/01/06/dc.xsd
          http://purl.org/dc/terms/
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
  xml = ::Builder::XmlMarkup.new
  xml.tag! 'description' do
    xml.tag! 'olac-archive', 'xmlns' => 'http://www.language-archives.org/OLAC/1.1/olac-archive', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'type' => 'institutional', 'currentAsOf' => '2012-05-15', 'xsi:schemaLocation' => 'http://www.language-archives.org/OLAC/1.1/olac-archive http://www.language-archives.org/OLAC/1.1/olac-archive.xsd' do
      xml.tag! 'archiveURL', 'http://paradisec.org.au'
      xml.tag! 'participant', 'name' => 'Linda Barwick',  'role' => 'Project Director', 'email' => 'Linda.Barwick@arts.usyd.edu.au'
      xml.tag! 'participant', 'name' => 'Nick Thieberger', 'role' => 'Project Manager',  'email' => 'thien@unimelb.edu.au'
      xml.tag! 'institution', 'A consortium made up of the University of Melbourne, University of Sydney, and the Australian National University'
      xml.tag! 'institutionURL', 'http://paradisec.org.au'
      xml.tag! 'shortLocation', 'Melbourne, Sydney, Canberra, Australia'
      xml.tag! 'location', 'Project Director based at the Department of Linguistics, University of Sydney, Transient Building, F12 University of Sydney, NSW 2006. Project Manager based at the School of Linguistics and Applied Linguistics, University of Melbourne, Victoria 3010, Australia'
      xml.tag! 'synopsis', 'PARADISEC (Pacific And Regional Archive for Digital Sources in Endangered Cultures) offers a facility for digital conservation and access for endangered ethnographic materials from the Pacific region, defined broadly to include Oceania and East and South east Asia. Only 6702 of the items listed here are currently digitised. The non-digitised items are part of an assessment of the scope of work that needs to be digitised. They also make otherwise inaccessible material discoverable.'
      xml.tag! 'access', 'The current focus of PARADISEC is securing endangered materials. Access to the datastore is by password and is currently only available to depositors via the following URL: http://www.paradisec.org.au/repository/[CollectionID]/[ItemID]. Page images of some fieldnotes can be located online.'
    end
  end
  extra_description xml
end
