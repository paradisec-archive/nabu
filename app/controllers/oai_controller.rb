class OaiController < ApplicationController
  def item
    provider = ItemProvider.new

    options = create_options('item')
    response =  provider.process_request(options)

    render :body => response, :content_type => 'text/xml'
  end

  def collection
    provider = CollectionProvider.new

    options = create_options('collection')
    response =  provider.process_request(options)

    render :body => response, :content_type => 'text/xml'
  end

  private
  def permitted_params
    params.permit(:verb, :identifier, :metadataPrefix, :set, :from, :until, :resumptionToken)
  end

  def create_options(model)
    params = permitted_params.to_h
    params.merge!(url: "#{request.base_url}#{request.path}")

    # OAI library has a bug
    token = params.delete('resumptionToken')
    params.merge!(resumption_token: token) if token

    params
  end
end
