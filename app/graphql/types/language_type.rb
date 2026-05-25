class Types::LanguageType < Types::BaseObject
  field :archive_link, String, method: :language_archive_link, null: true, camelize: false
  field :code, String, null: false
  field :countries, [Types::CountryType, null: true], null: true
  field :id, ID, null: false
  field :items_for_content, [Types::ItemType, null: true], null: true, camelize: false
  field :items_for_language, [Types::ItemType, null: true], null: true, camelize: false
  field :name, String, null: false
  field :retired, Boolean, null: true

  # TODO: this should be loaded through Item relationships instead
  field :collection, [Types::CollectionType, null: true], null: true
end
