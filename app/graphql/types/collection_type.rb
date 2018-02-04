Types::CollectionType = GraphQL::ObjectType.define do
  name 'Collection'

  field :id, !types.ID
  field :identifier, !types.String
  field :title, !types.String
  field :description, types.String
  field :collector, Types::PersonType
  field :operator, Types::PersonType
  field :university, Types::UniversityType
  field :field_of_research, Types::FieldOfResearchType
  field :grants, types[Types::GrantType]
  field :subject_languages, types[Types::LanguageType] do
    resolve -> (obj, args, ctx) {
      obj.subject_languages.uniq
    }
  end
  field :content_languages, types[Types::LanguageType] do
    resolve -> (obj, args, ctx) {
      obj.content_languages.uniq
    }
  end
  field :countries, types[Types::CountryType] do
    resolve -> (obj, args, ctx) {
      obj.item_countries.uniq
    }
  end
  field :access_class, types.String
  field :access_narrative, types.String
  field :region, types.String
  field :metadata_source, types.String
  field :orthographic_notes, types.String
  field :media, types.String
  field :comments, types.String
  field :complete, types.Boolean
  field :tape_location, types.Boolean
  field :boundaries, Types::BoundaryType
  field :doi, types.String
  field :doi_xml, types.String, property: :to_doi_xml
  field :citation, types.String
  field :permalink, !types.String, property: :full_path
end
