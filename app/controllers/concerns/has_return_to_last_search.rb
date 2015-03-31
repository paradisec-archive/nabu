require 'active_support/concern'

module HasReturnToLastSearch
  extend ActiveSupport::Concern

  included do
    # store and retrieve search params in session to mimic result set behaviour and allow 'return to last search' action
    # FIXME: this re-runs the search every time, and may become resource intensive if the datastore gets large
    # FIXME: may be worth just re-implementing result sets
    before_filter :manage_session_search_params, :only => [:search, :advanced_search]
  end

  def return_to_last_search
    if session[:search_from] and session[:search_params]
      redirect_to session.delete(:search_from).merge(session.delete(:search_params))
      return # avoid dropping through to fallback redirect
    end
    redirect_to controller: params[:controller], action: :search
  end

  # utility method to keep the multiple uses of this proc consistent w/ no typos
  def only_action_params
    Proc.new {|k,v| %w(controller action).include?(k)}
  end

  def should_apply_session_params?
    # if we're coming to the same page (e.g. visiting basic search with saved basic search)...
    if session[:search_from] == params.select(&only_action_params)
      # ... and there are saved params
      return session[:search_params].present?
    end

    false
  end

  # store or retrieve search params to mimic result sets
  def manage_session_search_params
    # if there are incoming params, ignore the session
    if (params.keys - %w(action controller utf8)).any?
      if params[:clear]
        session.delete(:search_from)
        session.delete(:search_params)
      else
        session[:search_from] = params.select(&only_action_params)
        session[:search_params] = params.reject(&only_action_params)
      end
    elsif should_apply_session_params?
      # otherwise use the session (delete it as you go to avoid infinite loops)
      redirect_to session.delete(:search_from).merge(session.delete(:search_params))
    end

    true
  end
end