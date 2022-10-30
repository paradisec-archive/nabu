class Types::AccessConditionType < Types::BaseObject

  field :name, String, null: true
  field :items, [Types::ItemType, null: true], null: true
  field :collections, [Types::CollectionType, null: true], null: true
end
