module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    def current_ability
      context[:current_ability]
    end

    def authorize!(*args)
      current_ability.authorize!(*args)
    end
  end
end
