class Types::FieldOfResearchType < Types::BaseObject
  field :collections, [Types::CollectionType, null: true], null: true
  field :id, ID, null: false
  field :identifier, String, null: false
  field :name, String, null: false
end
