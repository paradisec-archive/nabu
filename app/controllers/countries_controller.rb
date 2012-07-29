class CountriesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    @countries = Country.order('name').where('name like ?', "%#{params[:q]}%").limit(10)

    respond_with @countries
  end

  def show
    @country = Country.find params[:id]
    respond_with @country
  end
end
