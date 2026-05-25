class Types::CountryType < Types::BaseObject
  field :boundaries, [Types::BoundaryType, null: true], method: :latlon_boundary, null: true
  field :code, String, null: false
  field :id, ID, null: false
  field :languages, [Types::LanguageType, null: true], null: true
  field :name, String, null: false
end
