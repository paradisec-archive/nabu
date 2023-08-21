require 'net/http'
require 'srv_lookup'

BASE_URL = Rails.configuration.proxyist_url

# NOTE: This implementation of proxyist assumes S3 with redirect turned on for performance reasons

module Net
  class HTTP < Protocol
    def self.put(url, data, header = nil)
      start(url.hostname, url.port, use_ssl: url.scheme == 'https') do |http|
        http.put(url.path, data, header)
      end
    end

    def self.head(url)
      start(url.hostname, url.port, use_ssl: url.scheme == 'https') do |http|
        http.head(url.path)
      end
    end
  end
end

module Proxyist
  def self.get_object(identifier, filename, params = {})
    url = SrvLookup.http("#{BASE_URL}/object/#{identifier}/#{filename}")
    url += '?disposition=attachment' if params[:download]

    response = Net::HTTP.get_response(url)

    raise 'Proxyist is misonfigured, we only support redirects' unless response.is_a?(Net::HTTPRedirection)

    response['Location']
  end

  def self.upload_object(identifier, filename, data, headers = nil)
    url = SrvLookup.http("#{BASE_URL}/object/#{identifier}/#{filename}")

    Net::HTTP.put(url, data, headers)
  end

  def self.exists?(identifier, filename)
    url = SrvLookup.http("#{BASE_URL}/object/#{identifier}/#{filename}")

    Net::HTTP.head(url)
  end
end
