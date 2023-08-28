require 'resolv'
require 'sunspot_rails'
require_relative '../srv_lookup'

# Support SRV records like http+srv://example.com
module Sunspot
  module Rails
    class Configuration
      protected

      def solr_url
        return unless ENV['SOLR_URL'] || ENV['WEBSOLR_URL']

        url = ENV['SOLR_URL'] || ENV.fetch('WEBSOLR_URL', nil)

        SrvLookup.http(url)
      end
    end

    module Searchable
      module ClassMethods
        def solr_search(options = {}, &)
          attempts = 0

          begin
            attempts += 1
            solr_execute_search(options) do
              Sunspot.new_search(self, &)
            end
          rescue RSolr::Error::ConnectionRefused
            ::Rails.logger.info 'Solr connection refused retrying'
            Sunspot.session = Sunspot::Rails.build_session(Sunspot::Rails::Configuration.new)
            raise unless attempts < 10

            sleep 1
            retry
          end
        end
      end
    end
  end
end
