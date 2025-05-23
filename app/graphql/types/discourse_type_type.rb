class Types::DiscourseTypeType < Types::BaseObject
  field :id, ID, null: false
  field :name, String, null: false
  field :items, [Types::ItemType, null: true], null: true
end
