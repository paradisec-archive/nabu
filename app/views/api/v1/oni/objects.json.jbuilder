json.set! 'total', @data.size

json.set! 'data', @data do |data|
  type = data.class.name

  json.conformsTo "https://purl.archive.org/language-data-commons/profile##{type}"

  collection = type == 'Collection' ? data.identifier : data.collection.identifier
  item = type == 'item' ? "/#{data.identifier}" : ''
  json.crateId "http://catalog.paradisec.org.au/repository/#{collection}#{item}"

  json.record do
    json.name data.title
    json.license data.access_condition_name
    json.description data.description
  end
end
