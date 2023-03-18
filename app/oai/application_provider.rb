require 'oai/provider'

class ApplicationProvider < OAI::Provider::Base
  repository_name 'Pacific And Regional Archive for Digital Sources in Endangered Cultures (PARADISEC)'
  record_prefix 'oai:paradisec.org.au'
  admin_email 'thien@unimelb.edu.au'
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
        'xsi:schemaLocation' => %{
            http://ands.org.au/standards/rif-cs/registryObjects
            http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd
        }
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

# validate_identifier(params)
# validate_dates(params)
# validate_granularity(params)
#
# def validate_identifier(params)
#   if params["identifier"] && params["identifier"] !~ /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[\-;:&=\+\$,\w]+@)?[A-Za-z0-9\.\-]+|(?:www\.|[\-;:&=\+\$,\w]+@)[A-Za-z0-9\.\-]+)((?:\/[\+~%\/\.\w\-_]*)?\??(?:[\-\+=&;%@\.\w_]*)#?(?:[\.\!\/\\\w]*))?)/
#     raise OAI::ArgumentException.new
#   end
# end
#
# def validate_dates(params)
#   if params["from"]
#     raise OAI::ArgumentException.new if Timeliness.parse(params["from"]) == nil
#   end
#
#   if params["until"]
#     raise OAI::ArgumentException.new if Timeliness.parse(params["until"]) == nil
#   end
# end
#
# def validate_granularity(params)
#   if params["from"] && params["until"]
#     from_parse_result = begin
#                          Time.iso8601(params["from"])
#                        rescue ArgumentError
#                          :parse_failure
#                        end
#
#     from_parse_result = :parsed_correctly if from_parse_result.is_a?(Time)
#
#     until_parse_result = begin
#                          Time.iso8601(params["until"])
#                        rescue ArgumentError
#                          :parse_failure
#                        end
#
#     until_parse_result = :parsed_correctly if until_parse_result.is_a?(Time)
#
#     unless from_parse_result == until_parse_result
#       raise OAI::ArgumentException.new
#     end
#   end
# end
