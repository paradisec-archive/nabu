class Types::ItemResultType < Types::BaseObject
  field :next_page, Integer, null: true, camelize: false
  field :results, [Types::ItemType, null: true], null: false
  field :total, Integer, null: false
end
