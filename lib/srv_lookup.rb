require 'uri'

module SrvLookup
  def self.http(url)
    temp_url = URI.parse(url)
    return temp_url if temp_url.scheme != 'http+srv'

    resolv = Resolv::DNS.new
    srv_records = resolv.getresources(temp_url.hostname, Resolv::DNS::Resource::IN::SRV)

    raise "No SRV records found for #{temp_url}" if srv_records.empty?

    srv = srv_records.first

    temp_url.scheme = 'http'
    temp_url.hostname = srv.target.to_s
    temp_url.port = srv.port

    temp_url
  end
end
