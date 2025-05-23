require 'oai/provider'

class ApplicationProvider < OAI::Provider::Base
  repository_name 'Pacific And Regional Archive for Digital Sources in Endangered Cultures (PARADISEC)'
  record_prefix 'oai:paradisec.org.au'
  admin_email 'thien@unimelb.edu.au'
  update_granularity OAI::Const::Granularity::LOW
end

module OAI::Provider::Metadata
  class Rif < Format
    def initialize
      @prefix = 'rif'
      @schema = 'http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd'
      @namespace = 'http://ands.org.au/standards/rif-cs/registryObjects'
    end

    def header_specification
      {
        'xmlns'              => 'http://ands.org.au/standards/rif-cs/registryObjects',
        'xmlns:xsi'          => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => %(
            http://ands.org.au/standards/rif-cs/registryObjects
            http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd
        )
      }
    end
  end
end
OAI::Provider::Base.register_format(OAI::Provider::Metadata::Rif.instance)

module OAI::Provider::Metadata
  class Olac < Format
    def initialize
      @prefix = 'olac'
      @schema = 'http://www.language-archives.org/OLAC/1.1/olac.xsd'
      @namespace = 'http://www.language-archives.org/OLAC/1.1/'
      @element_namespace = 'olac'
    end

    def header_specification
      locations = %w[
        http://www.openarchives.org/OAI/2.0/oai_dc/
        http://www.openarchives.org/OAI/2.0/oai_dc.xsd
        http://purl.org/dc/elements/1.1/
        http://www.language-archives.org/OLAC/1.1/dc.xsd
        http://purl.org/dc/terms/
        http://www.language-archives.org/OLAC/1.1/dcterms.xsd
        http://www.language-archives.org/OLAC/1.1/
        http://www.language-archives.org/OLAC/1.1/olac.xsd
      ]

      {
        'xmlns:xsi'     => 'http://www.w3.org/2001/XMLSchema-instance',
        'xmlns:oai_dc'  => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
        'xmlns:dc'      => 'http://purl.org/dc/elements/1.1/',
        'xmlns:dcterms' => 'http://purl.org/dc/terms/',
        'xmlns:olac'    => 'http://www.language-archives.org/OLAC/1.1/',
        'xsi:schemaLocation' => locations.join(' ')
      }
    end
  end
end
OAI::Provider::Base.register_format(OAI::Provider::Metadata::Olac.instance)
