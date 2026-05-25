require 'active_support/concern'

module HasReturnToLastSearch
  extend ActiveSupport::Concern

  ROUTE_KEYS = %i[controller action format].freeze

  included do
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :manage_session_search_params, only: %i[search advanced_search]
    # rubocop:enable Rails/LexicallyScopedActionFilter
  end

  private

  # Host controller must define this and return an array of strong-params keys
  # (the same shape you'd pass to `params.permit(*keys)`). Used to scope what
  # gets persisted to the session so the "Return to Results" link can rebuild
  # the URL without trusting arbitrary user input.
  def permitted_search_param_keys
    raise NotImplementedError, "#{self.class.name} must define `permitted_search_param_keys`"
  end

  def manage_session_search_params
    permitted = params.permit(*permitted_search_param_keys, *ROUTE_KEYS)
    filters = permitted.except(*ROUTE_KEYS).to_h

    if filters.empty?
      session.delete(:search_from)
      session.delete(:search_params)
    else
      session[:search_from] = permitted.slice(*ROUTE_KEYS).to_h
      session[:search_params] = filters
    end
  end
end
