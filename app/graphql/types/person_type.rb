class Types::PersonType < Types::BaseObject

  field :id, ID, null: false
  field :first_name, String, null: true
  field :last_name, String, null: true
  field :name, String, null: true
  field :country, String, null: true
  field :collected_items, Types::ItemType, method: :owned_items, null: true
end
