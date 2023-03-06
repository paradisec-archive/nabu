class Types::ItemResultType < Types::BaseObject

  field :total, Integer, null: false
  field :next_page, Integer, null: true, camelize: false
  field :results, [Types::ItemType, null: true], null: false
end
