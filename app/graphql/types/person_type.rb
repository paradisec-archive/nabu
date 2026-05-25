class Types::PersonType < Types::BaseObject
  field :collected_items, Types::ItemType, method: :owned_items, null: true, camelize: false
  field :country, String, null: true
  field :first_name, String, null: true, camelize: false
  field :id, ID, null: false
  field :last_name, String, null: true, camelize: false
  field :name, String, null: true
end
