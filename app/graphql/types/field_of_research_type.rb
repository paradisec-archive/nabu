Types::FieldOfResearchType = GraphQL::ObjectType.define do
  name 'FieldOfResearch'

  field :id, !types.ID
  field :identifier, !types.String
  field :name, !types.String
  field :collections, types[Types::CollectionType]
end