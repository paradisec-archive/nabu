class Types::CollectionType < Types::BaseObject

  field :id, ID, null: false
  field :identifier, String, null: false
  field :title, String, null: false
  field :description, String, null: true
  field :collector, Types::PersonType, null: true
  field :operator, Types::PersonType, null: true
  field :university, Types::UniversityType, null: true
  field :field_of_research, Types::FieldOfResearchType, null: true
  field :grants, [Types::GrantType, null: true], null: true
  field :subject_languages, [Types::LanguageType, null: true], null: true

  def subject_languages
    object.subject_languages.uniq
  end
  field :content_languages, [Types::LanguageType, null: true], null: true

  def content_languages
    object.content_languages.uniq
  end
  field :countries, [Types::CountryType, null: true], null: true

  def countries
    object.item_countries.uniq
  end
  field :access_class, String, null: true
  field :access_narrative, String, null: true
  field :region, String, null: true
  field :metadata_source, String, null: true
  field :orthographic_notes, String, null: true
  field :media, String, null: true
  field :comments, String, null: true
  field :complete, Boolean, null: true
  field :tape_location, Boolean, null: true
  field :boundaries, Types::BoundaryType, null: true
  field :doi, String, null: true
  field :doi_xml, String, method: :to_doi_xml, null: true
  field :citation, String, null: true
  field :permalink, String, method: :full_path, null: false
end
