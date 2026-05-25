class Types::DataCategoryType < Types::BaseObject
  field :id, ID, null: false
  field :items, [Types::ItemType, null: true], null: true
  field :name, String, null: false
end
