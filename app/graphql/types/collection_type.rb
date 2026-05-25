class Types::CollectionType < Types::BaseObject
  field :id, ID, null: false

  field :content_languages, [Types::LanguageType, null: true], null: true, camelize: false


  field :countries, [Types::CountryType, null: true], null: true


  field :access_class, String, null: true, camelize: false


  field :access_narrative, String, null: true, camelize: false


  field :region, String, null: true


  field :metadata_source, String, null: true, camelize: false


  field :orthographic_notes, String, null: true, camelize: false


  field :media, String, null: true


  field :comments, String, null: true


  field :complete, Boolean, null: true


  field :tape_location, Boolean, null: true, camelize: false


  field :boundaries, Types::BoundaryType, null: true


  field :doi, String, null: true


  field :doi_xml, String, method: :to_doi_xml, null: true, camelize: false


  field :citation, String, null: true


  field :permalink, String, method: :full_path, null: false

  field :collector, Types::PersonType, null: true
  field :description, String, null: true
  field :field_of_research, Types::FieldOfResearchType, null: true, camelize: false
  field :grants, [Types::GrantType, null: true], null: true
  field :identifier, String, null: false
  field :operator, Types::PersonType, null: true
  field :subject_languages, [Types::LanguageType, null: true], null: true, camelize: false
  field :title, String, null: false
  field :university, Types::UniversityType, null: true

  def subject_languages
    object.subject_languages.uniq
  end

  def content_languages
    object.content_languages.uniq
  end

  def countries
    object.item_countries.uniq
  end
end
