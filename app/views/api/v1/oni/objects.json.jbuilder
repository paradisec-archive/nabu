json.total @data.size

json.data @data do |data|
  class_name = data.class.name
  is_collection = class_name == 'Collection'

  json.conformsTo "https://purl.archive.org/language-data-commons/profile##{class_name}"

  json.crateId is_collection ? repository_collection_url(data) : repository_item_url(data.collection, data)

  json.record do
    json.name data.title
    json.license data.access_condition_name
    json.description data.description
  end
end
