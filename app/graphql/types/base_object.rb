module Types
  class BaseObject < GraphQL::Schema::Object
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    def current_ability
      context[:current_ability]
    end

    def authorize!(*args)
      current_ability.authorize!(*args)
    end
  end
end
