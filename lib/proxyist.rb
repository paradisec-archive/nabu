require 'net/http'

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

    def self.delete(url)
      start(url.hostname, url.port, use_ssl: url.scheme == 'https') do |http|
        http.delete(url.path)
      end
    end
  end
end

module Proxyist
  def self.list(identifier)
    url = "#{BASE_URL}/object/#{identifier}"

    response = Net::HTTP.get_response(URI.parse(url))

    raise 'Proxyist request failed' unless response.is_a?(Net::HTTPOK)

    JSON.parse(response.body)
  end

  def self.get_object(identifier, filename, params = {})
    url = "#{BASE_URL}/object/#{identifier}/#{filename}"
    url += '?disposition=attachment' if params[:download]

    response = Net::HTTP.get_response(URI.parse(url))

    return if response.is_a?(Net::HTTPNotFound)

    raise 'Proxyist is misonfigured, we only support redirects' unless response.is_a?(Net::HTTPRedirection)

    response['Location']
  end

  def self.upload_object(identifier, filename, data, headers = nil)
    url = "#{BASE_URL}/object/#{identifier}/#{filename}"

    Net::HTTP.put(URI.parse(url), data, headers)
  end

  def self.delete_object(identifier, filename)
    url = "#{BASE_URL}/object/#{identifier}/#{filename}"

    Net::HTTP.delete(URI.parse(url))
  end

  def self.exists?(identifier, filename)
    url = "#{BASE_URL}/object/#{identifier}/#{filename}"

    Net::HTTP.head(URI.parse(url))
  end
end
