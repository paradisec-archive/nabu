class Types::PersonType < Types::BaseObject
  field :id, ID, null: false
  field :first_name, String, null: true, camelize: false
  field :last_name, String, null: true, camelize: false
  field :name, String, null: true
  field :country, String, null: true
  field :collected_items, Types::ItemType, method: :owned_items, null: true, camelize: false
end
