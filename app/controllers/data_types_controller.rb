class DataTypesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    # No need for a limit, as the number of DataType objects is fairly small.
    @data_types = @data_types.order('name').where('name like ?', "%#{params[:q]}%")

    respond_with @data_types
  end

  def show
    respond_with @data_type
  end

  def data_type_params
    params.require(:data_type)
      .permit(:name)
  end
end
