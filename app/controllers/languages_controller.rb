class LanguagesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  PICKER_LIMIT = 20
  SPECIAL_CODES = %w[mul und zxx].freeze

  def index
    hits = @languages.picker_search(params[:term] || params[:q]).limit(PICKER_LIMIT)
    hits = hits.where(id: CountriesLanguage.where(country_id: params[:country_ids]).select(:language_id)) if params[:country_ids]

    languages = (hits.to_a + Language.iso639_3.in_order_of(:code, SPECIAL_CODES).to_a).uniq

    render json: { results: languages.map { |l| { value: l.id, label: l.label, description: ('Retired' if l.retired) }.compact } }
  end

  def show
    respond_with @language
  end

  def language_params
    params.require(:language)
      .permit(:name, :code, :retired, :north_limit, :south_limit, :west_limit, :east_limit, :countries_languages_attributes)
  end
end
