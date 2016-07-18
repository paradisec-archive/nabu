class DataCategoriesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    # No need for a limit, as the number of DataCategory objects is fairly small.
    @data_categories = @data_categories.order('name').where('name like ?', "%#{params[:q]}%")

    respond_with @data_categories
  end

  def show
    respond_with @data_category
  end
end
