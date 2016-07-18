class DataTypesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    @data_types = @data_types.order('name').where('name like ?', "%#{params[:q]}%").limit(10)

    respond_with @data_types
  end

  def show
    respond_with @data_type
  end
end
