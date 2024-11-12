class CountriesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    @countries = @countries.order('name').where('name like ? OR code like ?', "%#{params[:q]}%", "%#{params[:q]}%").limit(10)

    render json: { results: @countries.map { |c| { id: c.id, text: c.name } } }
  end

  def show
    if params[:location_only]
      respond_with @country.latlon_boundary
    else
      respond_with @country
    end
  end

  def country_params
    params.require(:comment)
      .permit(:name, :code)
  end
end
