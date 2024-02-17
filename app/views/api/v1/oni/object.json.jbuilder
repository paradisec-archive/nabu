class_name = @data.class.name
is_collection = class_name == 'Collection'
url = is_collection ? repository_collection_url(@data) : repository_item_url(@data.collection, @data)

json.id url
json.crateId url
json.license @data.access_condition_name
json.name @data.title
json.description @data.description
json.createdAt @data.created_at
json.updatedAt @data.updated_at
json.rootConformsTo do
  json.id url
  json.crateId url
  json.conformsTo "https://purl.archive.org/language-data-commons/profile##{class_name}"
  json.recordId url
end
