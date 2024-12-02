class Types::AgentType < Types::BaseObject
  field :role_name, String, null: true, camelize: false
  field :user_name, String, null: true, camelize: false
  field :user, Types::PersonType, null: true
end
