class Types::UniversityType < Types::BaseObject
  field :id, ID, null: false
  field :name, String, null: false
  field :party_identifier, String, null: true, camelize: false

  field :items, [Types::ItemType, null: true], null: true
  field :collections, [Types::CollectionType, null: true], null: true
end
