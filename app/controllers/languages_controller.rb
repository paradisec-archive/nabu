class LanguagesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  PICKER_LIMIT = 20

  def index
    hits = @languages.picker_search(params[:term] || params[:q]).limit(PICKER_LIMIT)
    hits = hits.in_countries(params[:country_ids]) if params[:country_ids]

    languages = (hits.to_a + Language.special.to_a).uniq

    render json: { results: languages.map { |language| { value: language.id, label: language.label, description: language.picker_description }.compact } }
  end

  def show
    respond_with @language
  end

  def language_params
    params.require(:language)
      .permit(:name, :code, :retired, :north_limit, :south_limit, :west_limit, :east_limit, :countries_languages_attributes)
  end
end
