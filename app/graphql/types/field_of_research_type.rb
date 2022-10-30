class Types::FieldOfResearchType < Types::BaseObject

  field :id, ID, null: false
  field :identifier, String, null: false
  field :name, String, null: false
  field :collections, [Types::CollectionType, null: true], null: true
end