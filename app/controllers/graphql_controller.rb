class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  # avoid getting 401'd for not having a CSRF token
  skip_before_action :verify_authenticity_token, only: [:execute]

  before_action :check_auth, except: [:schema]

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_user:
    }
    result = NabuSchema.execute(query, variables: variables, context: context, operation_name: operation_name, max_complexity: 300)
    render json: result
  rescue StandardError => error
    raise error unless Rails.env.development?

    handle_error_in_development(error)
  end

  def schema
    render plain: NabuSchema.to_definition
  end

  private

  # since this is a JSON request, don't use authorize! which will try and redirect to login page
  def check_auth
    return if can? :graphql, Item

    render status: :unauthorized, json: { error: 'Must be logged in to query Nabu' }
  end

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(error)
    logger.error error.message
    logger.error error.backtrace.join("\n")

    render json: { errors: [{ message: error.message, backtrace: error.backtrace }], data: {} }, status: :internal_server_error
  end
end
