class GraphqlController < ApplicationController
  def execute
    # since this is a JSON request, don't use authorize! which will try and redirect to login page
    unless can? :graphql, Item
      render status: 401, json: {error: 'Must be logged in to query Nabu'}
      return
    end
    
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_user: current_user
    }
    result = NabuSchema.execute(query, variables: variables, context: context, operation_name: operation_name, max_complexity: 200)
    render json: result
  end

  def schema
    render text: NabuSchema.to_definition, content_type: 'text/plain'
  end

  private

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActiveSupport::HashWithIndifferentAccess
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end
end
