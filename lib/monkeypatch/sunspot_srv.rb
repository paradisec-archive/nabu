# Support SRV records like  https+srv://example.com

require 'resolv'

module Sunspot
  module Rails
    protected

    def solr_url
      return unless ENV['SOLR_URL'] || ENV['WEBSOLR_URL']

      temp_url = URI.parse(ENV['SOLR_URL'] || ENV['WEBSOLR_URL'])
      return temp_url if temp_url.scheme != 'https+srv'

      resolv = Resolv::DNS.new
      srv_records = resolv.getresources(temp_url.hostname, Resolv::DNS::Resource::IN::SRV)

      raise "No SRV records found for #{temp_url}" if srv_records.empty?

      srv = srv_records.first

      temp_url.schme = 'http'
      temp_url.target = srv.target
      temp_url.port = srv.port

      temp_url
    end
  end
end
