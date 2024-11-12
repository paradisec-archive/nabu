class DataTypesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    # No need for a limit, as the number of DataType objects is fairly small.
    @data_types = @data_types.order('name').where('name like ?', "%#{params[:q]}%")

    render json: { results: @data_types.map { |u| { id: u.id, text: u.name } } }
  end

  def show
    respond_with @data_type
  end

  def data_type_params
    params.require(:data_type)
      .permit(:name)
  end
end
