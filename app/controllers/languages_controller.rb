class LanguagesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  PICKER_LIMIT = 20

  def index
    hits = @languages.picker_search(params[:term] || params[:q]).limit(PICKER_LIMIT)
    hits = hits.in_countries(params[:country_ids]) if params[:country_ids]

    languages = (hits.to_a + Language.special.to_a).uniq
    offered = LanguageEquivalent.options_for(languages)

    render json: { results: languages.map { |language| language.picker_option(offered[language.id]) } }
  end

  def show
    respond_with @language
  end
end
