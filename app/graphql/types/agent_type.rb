class Types::AgentType < Types::BaseObject

  field :role_name, String, null: true
  field :user_name, String, null: true
  field :user, Types::PersonType, null: true
end
