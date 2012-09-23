class DataCategoriesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    @data_categories = @data_categories.order('name').where('name like ?', "%#{params[:q]}%").limit(10)

    respond_with @data_categories
  end

  def show
    respond_with @data_category
  end
end
