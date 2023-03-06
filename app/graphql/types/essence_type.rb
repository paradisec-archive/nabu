class Types::EssenceType < Types::BaseObject

  field :id, ID, null: false
  field :item, Types::ItemType, null: true
  field :collection, Types::CollectionType, null: true
  field :filename, String, null: true
  field :mimetype, String, null: true
  field :bitrate, Integer, null: true
  field :samplerate, Integer, null: true
  field :size, Integer, null: true
  field :duration, Float, null: true
  field :channels, Integer, null: true
  field :fps, Integer, null: true
  field :doi, String, null: true
  field :doi_xml, String, method: :to_doi_xml, null: true, camelize: false
  field :citation, String, null: true
  field :permalink, String, method: :full_path, null: false
end
