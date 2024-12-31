class OaiController < ApplicationController
  skip_forgery_protection

  def item
    provider = ItemProvider.new

    options = create_options('item')
    response = provider.process_request(options)
    response = update_xsd(response)

    render body: response, content_type: 'text/xml'
  end

  def collection
    provider = CollectionProvider.new

    options = create_options('collection')
    response = provider.process_request(options)
    response = update_xsd(response)

    render body: response, content_type: 'text/xml'
  end

  private

  def permitted_params
    params.permit(:verb, :identifier, :metadataPrefix, :set, :from, :until, :resumptionToken)
  end

  # NOTE: OLAC validator can't deal with redirects
  def update_xsd(response)
    response.gsub!('http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd', 'https://www.openarchives.org/OAI/2.0/OAI-PMH.xsd')
    response.gsub!('http://www.openarchives.org/OAI/2.0/oai-identifier.xsd', 'https://www.openarchives.org/OAI/2.0/oai-identifier.xsd')

    response
  end

  def create_options(_model)
    params = permitted_params.to_h
    params.merge!(url: "#{request.base_url}#{request.path}")

    # OAI library has a bug
    token = params.delete('resumptionToken')
    params.merge!(resumption_token: token) if token

    params
  end
end
