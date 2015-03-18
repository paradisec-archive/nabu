class CountriesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    @countries = @countries.order('name').where('name like ?', "%#{params[:q]}%").limit(10)

    respond_with @countries
  end

  def show
    if params[:location_only]
      respond_with @country.latlon_boundary
    else
      respond_with @country
    end
  end
end
