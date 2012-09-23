class LanguagesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def index
    @languages = @languages.order('languages.name').where('languages.name like ?', "%#{params[:q]}%").limit(10)
    if params[:country_ids]
      country_ids = params[:country_ids].split(/,/)
      # TODO there should be a better way of doing this
      @languages = @languages.where(:countries_languages => {:country_id => country_ids})
    end

    @languages.push(Language.find_by_code("mul"));
    @languages.push(Language.find_by_code("und"));
    @languages.push(Language.find_by_code("zxx"));
    respond_with @languages
  end

  def show
    respond_with @language
  end
end
