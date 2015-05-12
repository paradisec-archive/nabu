class OaiController < ApplicationController
  before_filter :set_access_headers

  def item
    # Remove controller and action from the options.  Rails adds them automatically.
    options = params.delete_if { |k,v| %w{controller action}.include?(k) }
    provider = ItemProvider.new
    response =  provider.process_request(options)
    render :text => response, :content_type => 'text/xml'
  end

  def collection
    # Remove controller and action from the options.  Rails adds them automatically.
    options = params.delete_if { |k,v| %w{controller action}.include?(k) }
    provider = CollectionProvider.new
    response =  provider.process_request(options)
    render :text => response, :content_type => 'text/xml'
  end

  private

  def set_access_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end
end
