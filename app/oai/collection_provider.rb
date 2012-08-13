require 'oai'

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
        'xsi:schemaLocation' => %{
            http://ands.org.au/standards/rif-cs/registryObjects
            http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd
        }
      }
    end

  end
end
OAI::Provider::Base.register_format(OAI::Provider::Metadata::Rif.instance)


class CollectionProvider < OAI::Provider::Base
  repository_name 'Pacific And Regional Archive for Digital Sources in Endangered Cultures (PARADISEC)'
  repository_url 'http://catalog.paradisec.org.au/oai/collection'
  record_prefix 'oai:paradisec.org.au'
  admin_email 'thien@unimelb.edu.au'
  source_model OAI::Provider::ActiveRecordWrapper.new(::Collection, :limit => 100)
end

