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
  end
end
