require 'uri'
require 'net/http'

class DoiMintingService
  def initialize(dry_run)
    @base_url = ENV.fetch('DATACITE_BASE_URL')
    @user = ENV.fetch('DATACITE_USER')
    @pass = ENV.fetch('DATACITE_PASS')
    @prefix = ENV.fetch('DOI_PREFIX')
    @dry_run = dry_run
  end

  def mint_doi(doiable)
    if @dry_run
      Rails.logger.info "DRY_RUN: DOI minting for #{doiable.id}"
      return
    end

    response = post '/dois', doiable.to_doi_json(@prefix)
    unless response
      Rails.logger.error "DOI minting failed for #{doiable.full_path}"
      return
    end

    doi = response['data']['id']

    Rails.logger.info "DOI #{doi} minted for #{doiable.full_path}"

    doiable.doi = doi
    doiable.save
  end

  private

  def url_for(action)
    "#{@base_url}#{action}"
  end

  def post(action, body)
    uri = URI.parse url_for(action)
    connection = Net::HTTP.new uri.host, uri.port
    connection.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Post.new uri.request_uri
    request['Content-Type'] = 'application/json'
    request.basic_auth @user, @pass
    request.body = body

    response = connection.request(request)

    if response.code != '201'
      Sentry.capture_message 'DOI creation failed', extra: { code: response.code, body: response.body }
      Rails.logger.error "DOI code: #{response.code}"
      Rails.logger.error "DOI response: #{response.body}"

      return
    end

    JSON.parse(response.body)
  end
end
