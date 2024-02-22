# frozen_string_literal: truemeta

@geos = []

def id
  @is_item ? repository_item_url(@data.collection, @data) : repository_collection_url(@data)
end

def rocrate_json(json)
  json.set! '@id', 'ro-crate-metadata.json'
  json.set! '@type', 'CreativeWork'
  json.conformsTo do
    json.set! '@id', 'https://w3id.org/ro/crate/1.2-DRAFT'
  end

  json.about do
    json.set! '@id', id
  end
end

def rocrate_collection_json(json)
  json.set! '@id', 'ro-crate-metadata.json'
  json.set! '@type', 'CreativeWork'
  json.conformsTo do
    json.set! '@id', 'https://w3id.org/ro/crate/1.2-DRAFT'
  end
  json.about do
    json.set! '@id', api_v1_oni_object_meta({ id: })
  end
end

def role_id(role)
  "#role-#{role.name}"
end

def role_json(json, role)
  json.set! '@id', role_id(role)
  json.set! '@type', 'Role'
  json.name role.name
end

def contact_json(json)
  json.set! '@id', 'admin@paradisec.org.au'
  json.set! '@type', 'ContactPoint'
  json.contactType 'customer service'
  json.email 'admin@paradisec.org.au'
  json.identifier 'admin@paradisec.org.au'
  json.url 'https://paradisec.org.au'
end

def person_id(user)
  user.party_identifier || (user.email && "mailto:#{user.email}") || "#person-#{user.id}"
end

def person_json(json, user)
  json.set! '@id', person_id(user)
  json.set! '@type', 'Person'
  json.email user.email if user.email
  json.familyName user.last_name
  json.givenName user.first_name
  json.name user.name
end

def essence_id(essence)
  repository_essence_url(essence.collection, essence.item, essence.filename)
end

def essence_json(json, essence)
  json.set! '@id', essence_id(essence)
  json.set! '@type', 'File'
  json.bitrate essence.bitrate if essence.bitrate
  json.contentSize essence.size
  json.dateCreated essence.created_at.to_date
  json.dateModified essence.updated_at.to_date
  json.duration essence.duration if essence.duration
  json.encodingFormat essence.mimetype
  json.name essence.filename
  json.channels essence.channels if essence.channels
  json.doi essence.doi
  json.essenceId essence.id # Should we expose this????
  json.sampleRate essence.samplerate if essence.samplerate
end

def geometry_id(shape)
  "#geo-#{shape.west_limit},#{shape.south_limit}-#{shape.east_limit},#{shape.north_limit}"
end

def geometry_json(json, data)
  json.set! '@id', geometry_id(data)
  json.set! '@type', 'Geometry'
  coords = [
    "#{data.west_limit} #{data.north_limit}",
    "#{data.east_limit} #{data.north_limit}",
    "#{data.east_limit} #{data.south_limit}",
    "#{data.west_limit} #{data.south_limit}",
    "#{data.west_limit} #{data.north_limit}"
  ]
  json.asWKT "POLYGON((#{coords.join(', ')}))"
end

def place_id(place, name = nil)
  name ? "#place-#{name}" : "#place-#{place.west_limit},#{place.south_limit}-#{place.east_limit},#{place.north_limit}"
end

def place_json(json, place, name = nil)
  json.set! '@id', place_id(place, name)
  json.name name if name
  json.set! '@type', 'Place'
  json.geo do
    json.set! '@id', geometry_id(place)
  end
  @geos << place
end

def country_id(country)
  "#country-#{country.name}"
end

def country_json(json, country)
  json.set! '@id', country_id(country)
  json.set! '@type', 'Country'
  json.code country.code
  json.name country.name
end

def propery_value_identifier(name)
  "#identifier_#{name}"
end

def property_value_json(json, name, value)
  json.set! '@id', propery_value_identifier(name)
  json.set! '@type', 'PropertyValue'
  json.name name
  json.value value
end

def language_id(language)
  "#language-#{language.code}"
end

def language_json(json, language)
  json.set! '@id', language_id(language)
  json.set! '@type', 'Language'
  json.code language.code
  json.location do
    json.set! '@id', geometry_id(language)
  end
  json.name language.name

  @geos << language
end

def access_condition_id(access_condition)
  "#license-#{access_condition.id}"
end

def access_condition_json(json, access_condition)
  json.set! '@id', access_condition_id(access_condition)
  json.set! '@type', 'CreativeWork'
  json.name access_condition.name
end

def organisation_id(organisation)
  organisation.party_identifier
end

def organisation_json(json, organisation)
  json.set! '@id', organisation_id(organisation)
  json.set! '@type', 'Organisation'
  json.name organisation.name
end

json.set! '@context', [
  'https://w3id.org/ro/crate/1.2-DRAFT/context',
  { '@vocab': 'http://schema.org/' },
  'http://purl.archive.org/language-data-commons/context.json',
  { Geometry: 'http://www.opengis.net/ont/geosparql#Geometry', asWKT: 'http://www.opengis.net/ont/geosparql#asWKT' },
  'https://w3id.org/ldac/context'
]

# rubocop:disable Metrics/BlockLength
json.set! '@graph' do
  json.child! { place_json(json, @data, @data.region) } if @data.region

  json.array! @data.countries do |country|
    country_json(json, country)
  end

  json.child! { property_value_json(json, 'collectionIdentifier', @data.collection.identifier) } if @is_item

  json.child! { property_value_json(json, 'doi', @data.doi) }
  json.child! { property_value_json(json, 'domain', 'paradisec.org.au') }
  json.child! { property_value_json(json, 'id', @data.full_identifier) }
  json.child! { property_value_json(json, 'itemIdentifier', @data.identifier) }

  languages = (@data.content_languages + @data.subject_languages).uniq(&:code)
  json.array! languages.each do |lang|
    language_json(json, lang)
  end

  json.child! { place_json(json, @data) }
  json.child! { geometry_json(json, @data) }

  # The item or collection
  json.child! do
    json.set! '@id', id
    json.set! '@type', %w[Data Object RepositoryObject]
    json.additionalType @is_item ? 'item' : 'collection'

    json.contentLocation do
      json.child! { json.set! '@id', place_id(@data, @data.region) }
    end

    if @is_item
      json.contributor do
        json.array! @data.item_agents do |item_agent|
          json.set! '@id', person_id(item_agent.user)
        end
      end
    end

    json.dateCreated @data.created_at.to_date
    json.dateModified @data.updated_at.to_date
    json.datePublished @data.updated_at.to_date
    json.description @data.description

    if @is_item
      json.hasPart do
        json.array! @data.essences do |essence|
          json.set! '@id', essence_id(essence)
        end
      end
    end

    json.identifier do
      json.child! { json.set! '@id', propery_value_identifier('domain') }
      json.child! { json.set! '@id', propery_value_identifier('id') }
      json.child! { json.set! '@id', propery_value_identifier('itemId') }
      json.child! { json.set! '@id', propery_value_identifier('collectionId') }
      json.child! { json.set! '@id', propery_value_identifier('doi') }
    end

    json.license { json.set! '@id', access_condition_id(@data.access_condition) } if @data.access_condition
    json.conformsTo { json.set! '@id', 'https://w3id.org/ldac/profile#Object' }
    json.memberOf { json.set! '@id', repository_collection_url(@data.collection) } if @is_item

    json.name @data.title

    json.publisher { json.set! '@id', person_id(@data.collector) }

    json.bornDigital @data.born_digital if @is_item

    json.inLanguage do
      json.array! @data.content_languages do |language|
        json.set! '@id', language_id(language)
      end
    end

    json.countries do
      json.array! @data.countries do |country|
        json.set! '@id', country_id(country)
      end
    end

    if @is_item
      json.digitisedOn @data.digitised_on.to_date if @data.digitised_on
      json.external @data.external
      json.languageAsGiven @data.language
      json.metadataExportable @data.metadata_exportable
      json.originalMedia @data.original_media if @data.original_media
      json.originatedOn @data.originated_on.to_date if @data.originated_on
      json.tapesReturned @data.tapes_returned

      @data.item_agents.group_by(&:agent_role).map do |agent_role, item_agents|
        json.set! agent_role.name do
          json.array! item_agents do |item_agent|
            json.set! '@id', person_id(item_agent.user)
          end
        end
      end
    end

    json.private @data.private

    json.subjectLanguages do
      json.array! @data.subject_languages do |language|
        json.set! '@id', language_id(language)
      end
    end
  end

  if @is_item
    json.array! @data.item_agents.map(&:user).uniq do |user|
      person_json(json, user)
    end

    json.array! @data.essences do |essence|
      essence_json(json, essence)
    end
  end

  json.child! do
    access_condition_json(json, @data.access_condition)
  end

  if @data.university
    json.child! do
      organisation_json(json, @data.university)
    end
  end

  json.child! do
    rocrate_json(json)
  end

  geometries = @geos.uniq { |g| geometry_id(g) }
  json.array! geometries do |geo|
    geometry_json(json, geo)
  end
end
# rubocop:enable Metrics/BlockLength
