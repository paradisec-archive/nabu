require 'net/http'
require 'srv_lookup'

BASE_URL = Rails.configuration.proxyist_url

module Proxyist
  def self.get(path)
    url = SrvLookup.http("#{BASE_URL}#{path}")
    response = Net::HTTP.get_response(url)

    raise 'Proxyist is misonfigured, we only support redirects' unless response.is_a?(Net::HTTPRedirection)

    response['Location']
  end
end

