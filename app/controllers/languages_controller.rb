class LanguagesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    @languages = Language.order('languages.name').where('languages.name like ?', "%#{params[:q]}%").limit(10)
    if params[:country_ids]
      country_ids = params[:country_ids].split(/,/)
      # TODO there should be a better way of doing this
      @languages = @languages.where(:countries_languages => {:country_id => country_ids})
    end

    respond_with @languages
  end

  def show
    @language = Language.find params[:id]
    respond_with @language
  end
end
