class EssencesController < ApplicationController
  load_and_authorize_resource :collection, :find_by => :identifier
  load_and_authorize_resource :item, :find_by => :identifier, :through => :collection
  load_and_authorize_resource :essence, :through => :item

  def show
  end

  def download
    send_file @essence.path, :type => @essence.mimetype, :filename => @essence.filename
  end

end
