Types::LanguageType = GraphQL::ObjectType.define do
  name 'Language'

  field :id, !types.ID
  field :code, !types.String
  field :name, !types.String
  field :retired, types.Boolean
  field :archive_link, types.String, property: :language_archive_link
  field :countries, types[Types::CountryType]
  field :items_for_content, types[Types::ItemType]
  field :items_for_language, types[Types::ItemType]

  # TODO: this should be loaded through Item relationships instead
  field :collection, types[Types::CollectionType]
end
