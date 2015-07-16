require 'uri'
require 'net/http'

class DoiMintingService
  module AndsResponse
    MINTING_SUCCESS = 'MT001'
    UPDATE_SUCCESS = 'MT002'
    UNAVAILABLE = 'MT005'
  end

  def initialize
    @url = ENV['ANDS_CMD_URL']
    @app_id = ENV['ANDS_APP_ID']
    @shared_secret = ENV['ANDS_SHARED_SECRET']
  end

  def mint_doi(doiable)
    doi_xml = doiable.to_doi_xml
    uri = URI(@url)
    uri.query = URI.encode_www_form( app_id: @app_id, url: doiable.full_path)

    connection = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.path)
    response = connection.request(request)

    if response.status >= 200 && response.status < 300
      body = JSON.parse(response.body)
      if body['responsecode'] == AndsResponse::MINTING_SUCCESS
        doiable.doi = body['response']['doi']
      end
    else

    end
  end
  #{"response":{"type":"type","responsecode":"code","message":"message","doi":"doi","url":"url","app_id":"app_id","verbosemessage":"verbosemessage"}}
end