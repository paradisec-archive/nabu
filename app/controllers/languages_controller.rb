class LanguagesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    @languages = @languages
      .includes(:countries)
      .order('languages.name')
      .where('languages.name like ? OR languages.code like ?', "%#{params[:term] || params[:q]}%", "%#{params[:term] || params[:q]}%")
      .limit(10)

    @languages = @languages.where(countries_languages: { country_id: params[:country_ids] }) if params[:country_ids]

    @languages = @languages.to_a

    # These are fake languages which we always want in the list
    @languages << Language.find_by_code('mul')
    @languages << Language.find_by_code('und')
    @languages << Language.find_by_code('zxx')

    render json: { results: @languages.map { |l| { id: l.id, text: l.name } } }
  end

  def show
    respond_with @language
  end

  def language_params
    params.require(:language)
      .permit(:name, :code, :retired, :north_limit, :south_limit, :west_limit, :east_limit, :countries_languages_attributes)
  end
end
