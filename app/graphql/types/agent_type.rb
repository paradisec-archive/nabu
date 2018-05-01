Types::AgentType = GraphQL::ObjectType.define do
  name 'Agent'

  field :role_name, types.String
  field :user_name, types.String
  field :user, Types::PersonType
end
