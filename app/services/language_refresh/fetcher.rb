require 'net/http'

module LanguageRefresh
  # GETs a Source's file, retrying transient failures with exponential backoff.
  class Fetcher
    class FetchError < StandardError; end

    Response = Data.define(:url, :body, :version)

    RETRIES = 3
    TIMEOUT = 60
    MAX_REDIRECTS = 3
    USER_AGENT = 'Mozilla/5.0 (compatible; nabu-language-refresh)'.freeze

    TRANSIENT = [
      FetchError, Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError, EOFError, Timeout::Error
    ].freeze

    def initialize(backoff: 5)
      @backoff = backoff
    end

    def get(url)
      attempt = 0

      begin
        attempt += 1
        response = request(URI(url))
        Response.new(url:, body: utf8(response.body), version: version_of(response))
      rescue *TRANSIENT => e
        raise FetchError, "GET #{url} failed after #{attempt} attempts: #{e.message}" if attempt > RETRIES

        sleep(@backoff * (2**(attempt - 1)))
        retry
      end
    end

    private

    def request(uri, redirects = 0)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
        http.get(uri.request_uri, 'User-Agent' => USER_AGENT)
      end

      case response
      when Net::HTTPSuccess
        response
      when Net::HTTPRedirection
        raise FetchError, 'too many redirects' if redirects >= MAX_REDIRECTS

        request(URI.join(uri, response['Location']), redirects + 1)
      else
        raise FetchError, "HTTP #{response.code}"
      end
    end

    def utf8(body)
      body.to_s.dup.force_encoding(Encoding::UTF_8).delete_prefix("\uFEFF")
    end

    # Neither SIL nor Ethnologue versions its tables, so the file's own date stands in.
    def version_of(response)
      modified = response['Last-Modified']
      return Time.httpdate(modified).utc.to_date.iso8601 if modified

      "sha256:#{Digest::SHA256.hexdigest(response.body.to_s)[0, 12]}"
    rescue ArgumentError
      modified
    end
  end
end
