require 'resolv'
require 'sunspot_rails'

# Support SRV records like http+srv://example.com
module Sunspot
  module Rails
    class Configuration
      protected

      def solr_url
        return unless ENV['SOLR_URL'] || ENV['WEBSOLR_URL']

        temp_url = URI.parse(ENV['SOLR_URL'] || ENV['WEBSOLR_URL'])
        return temp_url if temp_url.scheme != 'http+srv'

        resolv = Resolv::DNS.new
        srv_records = resolv.getresources(temp_url.hostname, Resolv::DNS::Resource::IN::SRV)

        raise "No SRV records found for #{temp_url}" if srv_records.empty?

        srv = srv_records.first

        temp_url.scheme = 'http'
        temp_url.hostname = srv.target.to_s
        temp_url.port = srv.port

        puts "SOLR_URL SVR Lookup: #{ENV['SOLR_URL']} => #{temp_url}"

        temp_url
      end
    end
  end
end
