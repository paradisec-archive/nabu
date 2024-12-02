class Types::LanguageType < Types::BaseObject
  field :id, ID, null: false
  field :code, String, null: false
  field :name, String, null: false
  field :retired, Boolean, null: true
  field :archive_link, String, method: :language_archive_link, null: true, camelize: false
  field :countries, [Types::CountryType, null: true], null: true
  field :items_for_content, [Types::ItemType, null: true], null: true, camelize: false
  field :items_for_language, [Types::ItemType, null: true], null: true, camelize: false

  # TODO: this should be loaded through Item relationships instead
  field :collection, [Types::CollectionType, null: true], null: true
end
