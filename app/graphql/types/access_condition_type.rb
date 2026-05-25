class Types::AccessConditionType < Types::BaseObject
  field :collections, [Types::CollectionType, null: true], null: true
  field :items, [Types::ItemType, null: true], null: true
  field :name, String, null: true
end
