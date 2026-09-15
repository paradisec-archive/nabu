class Types::LanguageType < Types::BaseObject
  field :archive_link, String, method: :source_uri, null: true, camelize: false, deprecation_reason: 'Use source_uri'
  field :code, String, null: false
  field :countries, [Types::CountryType, null: true], null: true
  field :dialect, Boolean, null: false
  field :equivalents, [Types::LanguageEquivalentType], null: false
  field :id, ID, null: false
  field :items_for_content, [Types::ItemType, null: true], null: true, camelize: false
  field :items_for_language, [Types::ItemType, null: true], null: true, camelize: false
  field :name, String, null: false
  field :retired, Boolean, null: true
  field :source, Types::LanguageSourceEnum, null: false
  field :source_uri, String, null: true, camelize: false

  # TODO: this should be loaded through Item relationships instead
  field :collection, [Types::CollectionType, null: true], null: true

  def equivalents
    object.equivalents.includes(:language, :related_language).map do |pair|
      { language: pair.other_than(object), evidence: pair.evidence }
    end
  end
end
