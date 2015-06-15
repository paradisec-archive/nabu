class OaiController < ApplicationController
  def item
    # Remove controller and action from the options.  Rails adds them automatically.
    options = params.delete_if { |k,v| %w{controller action}.include?(k) }
    provider = ItemProvider.new
    response =  provider.process_request(options)

    # if this is development or staging, convert the OAI output to use the current host as the originating URL for everything
    unless request.host == 'catalog.paradisec.org.au'
      response = response.gsub('catalog.paradisec.org.au', "#{request.host}:#{request.port}")
    end

    render :text => response, :content_type => 'text/xml'
  end

  def collection
    # Remove controller and action from the options.  Rails adds them automatically.
    options = params.delete_if { |k,v| %w{controller action}.include?(k) }
    provider = CollectionProvider.new
    response =  provider.process_request(options)
    render :text => response, :content_type => 'text/xml'
  end
end
