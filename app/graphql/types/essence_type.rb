Types::EssenceType = GraphQL::ObjectType.define do
  name 'Essence'

  field :id, !types.ID
  field :item, Types::ItemType
  field :collection, Types::CollectionType
  field :filename, types.String
  field :mimetype, types.String
  field :bitrate, types.Int
  field :samplerate, types.Int
  field :size, types.Int
  field :duration, types.Float
  field :channels, types.Int
  field :fps, types.Int
  field :doi, types.String
  field :doi_xml, types.String, property: :to_doi_xml
  field :citation, types.String
  field :permalink, !types.String, property: :full_path
end
