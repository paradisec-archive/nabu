require 'active_support/concern'

module HasReturnToLastSearch
  extend ActiveSupport::Concern

  included do
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :manage_session_search_params, only: %i[search advanced_search]
    # rubocop:enable Rails/LexicallyScopedActionFilter
  end

  private

  def only_search_params
    proc { |k, _v| %w[controller action format].include?(k) }
  end

  # store or retrieve search params to mimic result sets
  def manage_session_search_params
    if params&.reject(&only_search_params)&.permit!.to_h.empty?
      session.delete(:search_from)
      session.delete(:search_params)
    else
      session[:search_from] = params.select(&only_search_params).permit!.to_h
      session[:search_params] = params.reject(&only_search_params).permit!.to_h
    end
  end
end
