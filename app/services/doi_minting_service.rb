require 'uri'
require 'net/http'

class DoiMintingService
  module AndsResponse
    MINTING_SUCCESS = 'MT001'
    UPDATE_SUCCESS = 'MT002'
    UNAVAILABLE = 'MT005'
  end

  def initialize(format)
    @base_url = ENV['ANDS_URL_BASE']
    @app_id = ENV['ANDS_APP_ID']
    @format = format.to_s
    # @shared_secret = ENV['ANDS_SHARED_SECRET']
  end

  def mint_doi(doiable)
    doi_xml = doiable.to_doi_xml
    uri = URI(url_for(:mint))
    uri.query = URI.encode_www_form( app_id: @app_id, url: doiable.full_path)

    connection = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.path)
    response = connection.request(request)

    if response.code >= 200 && response.code < 300
      content = JSON.parse(response.body)
      if content['response']['responsecode'] == AndsResponse::MINTING_SUCCESS
        doiable.doi = content['response']['doi']
        puts "Successfully minted DOI for #{doiable.full_path} => #{doiable.doi}"
      else
        puts "Failed to mint DOI - DOI minting return a bad response: #{content['response']['responsecode']} / #{content['response']['message']}"
        puts content['response']['verbosemessage']
      end
    else
      puts "Failed to mint DOI - Server returned a bad response: #{response.status} / #{response.message}"
    end
  end

  private

  def url_for(action)
    "#{@base_url}/#{action}.#{@format}/"
  end
end

=begin
# json response structure
{
  "response": {
    "type": "type",
    "responsecode": "code",
    "message": "message",
    "doi": "doi",
    "url": "url",
    "app_id": "app_id",
    "verbosemessage": "verbosemessage"
  }
}
=end