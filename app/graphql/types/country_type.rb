class Types::CountryType < Types::BaseObject
  field :id, ID, null: false
  field :code, String, null: false
  field :name, String, null: false
  field :languages, [Types::LanguageType, null: true], null: true
  field :boundaries, [Types::BoundaryType, null: true], method: :latlon_boundary, null: true
end
