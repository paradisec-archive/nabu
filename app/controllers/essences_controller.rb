class EssencesController < ApplicationController
  load_and_authorize_resource :essence, :through => :item, :shallow => true

  def show
  end

end
