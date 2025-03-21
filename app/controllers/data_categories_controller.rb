class DataCategoriesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    # No need for a limit, as the number of DataCategory objects is fairly small.
    @data_categories = @data_categories.order('name').where('name like ?', "%#{params[:q]}%")

    render json: { results: @data_categories.map { |u| { id: u.id, text: u.name } } }
  end

  def show
    respond_with @data_category
  end

  def data_category_params
    params.require(:comment)
      .permit(:name)
  end
end
