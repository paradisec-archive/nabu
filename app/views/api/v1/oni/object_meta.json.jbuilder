# frozen_string_literal: true

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
    json.set! '@id', api_v1_oni_object_meta_url({ id: })
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

def geo_shape_id(shape)
  "#geo-#{shape.west_limit},#{shape.south_limit}-#{shape.east_limit},#{shape.north_limit}"
end

def geo_shape_json(json, s)
  json.set! '@id', geo_shape_id(s)
  json.set! '@type', 'Geometry'
  json.asWKT "POLYGON((#{s.north_limit} #{s.west_limit}, #{s.north_limit} #{s.east_limit}, #{s.south_limit} #{s.east_limit}, #{s.south_limit} #{s.west_limit}, #{s.north_limit} #{s.west_limit}))"
end

def geo_place_id(place)
  "#place_geo-#{place.west_limit},#{place.south_limit}-#{place.east_limit},#{place.north_limit}"
end

def geo_place_json(json, place)
  json.set! '@id', geo_place_id(place)
  json.set! '@type', 'Place'
  json.geo do
    json.set! '@id', geo_shape_id(place)
  end
end

def place_id(name)
  "#place-#{name}"
end

def place_json(json, name)
  json.set! '@id', place_id(name)
  json.set! '@type', 'Place'
  json.name name
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
    json.set! '@id', geo_shape_id(language)
  end
  json.name language.name
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
  # The Ro-Crate itself
  # json.child! do
  #   contact_json(json)
  # end

  json.child! { place_json(json, @data.region) }

  json.array! @data.countries do |country|
    country_json(json, country)
  end

  languages = (@data.subject_languages + @data.content_languages).uniq { |language| geo_shape_id(language) }

  json.array! languages do |language|
    geo_shape_json(json, language)
  end

  json.child! { property_value_json(json, 'collectionIdentifier', @data.collection.identifier) } if @is_item

  json.child! { property_value_json(json, 'doi', @data.doi) }
  json.child! { property_value_json(json, 'domain', 'paradisec.org.au') }
  # TODO: What is this and how do we get it?
  json.child! do
    property_value_json(json, 'hashId', '72b3dc1401c8ff06aacba0990a128fc113cf9ad5275f494b05c')
  end
  json.child! { property_value_json(json, 'id', @data.full_identifier) }
  json.child! { property_value_json(json, 'itemIdentifier', @data.identifier) }

  json.array! (@data.content_languages + @data.subject_languages).uniq do |lang|
    language_json(json, lang)
  end

  json.child! { geo_place_json(json, @data) }
  json.child! { geo_shape_json(json, @data) }

  # The item
  json.child! do
    json.set! '@id', id
    json.set! '@type', %w[Dataset RepositoryObject]
    json.additionalType 'item'

    json.contentLocation do
      json.child! { json.set! '@id', place_id(@data.region) }
      json.child! { json.set! '@id', geo_place_id(@data) }
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
      json.child! { json.set! '@id', propery_value_identifier('hashId') }
      json.child! { json.set! '@id', propery_value_identifier('itemId') }
      json.child! { json.set! '@id', propery_value_identifier('collectionId') }
      json.child! { json.set! '@id', propery_value_identifier('doi') }
    end

    json.license { json.set! '@id', access_condition_id(@data.access_condition) }
    json.conformsTo { json.set! '@id', 'https://w3id.org/ldac/profile' }
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
      json.digitisedOn @data.digitised_on
      json.external @data.external
      json.languageAsGiven @data.language
      json.metadataExportable @data.metadata_exportable
      json.originalMedia @data.original_media
      json.originatedOn @data.originated_on
    end

    json.private @data.private

    json.subjectLanguages do
      json.array! @data.subject_languages do |language|
        json.set! '@id', language_id(language)
      end
    end
    json.tapesReturned @data.tapes_returned

    @data.item_agents.group_by(&:agent_role).map do |agent_role, item_agents|
      json.set! agent_role.name do
        json.array! item_agents do |item_agent|
          json.set! '@id', person_id(item_agent.user)
        end
      end
    end
  end

  json.array! @data.item_agents.map(&:user).uniq do |user|
    person_json(json, user)
  end

  json.array! @data.essences do |essence|
    essence_json(json, essence)
  end

  json.child! do
    access_condition_json(json, @data.access_condition)
  end

  json.child! do
    organisation_json(json, @data.university)
  end

  json.child! do
    rocrate_json(json)
  end

  # roles = grouped_item_agents.map { |grouped_item_agent| grouped_item_agent[:roles] }.flatten.uniq
  # json.array! roles do |role|
  #   role_json(json, role)
  # end
end
# rubocop:enable Metrics/BlockLength
