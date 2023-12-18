# frozen_string_literal: true

def rocrate_json(json)
  json.set! '@id', 'ro-crate-metadata.json'
  json.set! '@type', 'CreativeWork'
  json.conformsTo do
    json.set! '@id', 'https://w3id.org/ro/crate/1.2-DRAFT'
  end
  json.about do
    json.set! '@id', rocrate_collection_item_url(@item)
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

def person_json(json, user, roles)
  json.set! '@id', person_id(user)
  json.set! '@type', 'Person'
  json.email user.email if user.email
  json.familyName user.last_name
  json.givenName user.first_name
  json.name user.name
  # FIXME: Should this be roles?
  json.role roles do |role|
    json.set! '@id', role_id(role)
  end
end

def essence_id(essence)
  repository_essence_url(essence.collection, essence.item, essence.filename) 
end

def essence_json(json, essence)
  json.set! '@id', essence_id(essence)
  json.set! '@type', 'File'
  json.bitrate essence.bitrate if essence.bitrate
  json.contentSize essence.size
  json.dateCreated essence.created_at.utc
  json.dateModified essence.updated_at.utc
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
  json.set! '@type', 'gsp:wktLiteral'
  json.box "POLYGON((#{s.north_limit} #{s.west_limit}, #{s.north_limit} #{s.east_limit}, #{s.south_limit} #{s.east_limit}, #{s.south_limit} #{s.west_limit}, #{s.north_limit} #{s.west_limit}))";
end

def geo_place_id(place)
  "#place_geo-#{place.west_limit},#{place.south_limit}-#{place.east_limit},#{place.north_limit}"
end

# FIXME: Why does this exist?
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
  { gsp: 'http://www.opengis.net/ont/geosparql#' }
]

# rubocop:disable Metrics/BlockLength
json.set! '@graph' do
  # The Ro-Crate itself
  # json.child! do
  #   contact_json(json)
  # end

  json.child! { place_json(json, @item.region) }

  json.array! @item.countries do |country|
    country_json(json, country)
  end

  json.array! @item.subject_languages do |language|
    geo_shape_json(json, language)
  end
  json.array! @item.content_languages do |language|
    geo_shape_json(json, language)
  end

  json.child! { property_value_json(json, 'collectionIdentifier', @item.collection.identifier) }
  json.child! { property_value_json(json, 'doi', @item.doi) }
  json.child! { property_value_json(json, 'domain', 'paradisec.org.au') }
  # TODO: What is this and how do we get it?
  json.child! do
    property_value_json(json, 'hashId', '72b3dc1401c8ff06aacba0990a128fc113cf9ad5275f494b05c')
  end
  json.child! { property_value_json(json, 'id', @item.full_identifier) }
  json.child! { property_value_json(json, 'itemIdentifier', @item.identifier) }

  json.array! (@item.content_languages + @item.subject_languages).uniq do |lang|
    language_json(json, lang)
  end

  json.child! { geo_place_json(json, @item) }

  # The item
  json.child! do
    json.set! '@id', repository_item_url(@item.collection, @item)
    json.set! '@type', %w[Dataset RepositoryObject]
    json.additionalType 'item'

    json.contentLocation do
      json.child! { json.set! '@id', place_id(@item.region) }
      json.child! { json.set! '@id', geo_place_id(@item) }
    end

    json.contributor do
      json.array! @item.item_agents do |item_agent|
        json.set! '@id', person_id(item_agent.user)
      end
    end

    json.dateCreated @item.created_at.utc
    json.dateModified @item.updated_at.utc
    json.datePublished @item.updated_at.utc
    json.description @item.description
    json.hasPart do
      json.array! @item.essences do |essence|
        json.set! '@id', essence_id(essence)
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

    json.license { json.set! '@id', access_condition_id(@item.access_condition) }

    json.memberOf { json.set! '@id', repository_collection_url(@item.collection) }

    json.name @item.title

    json.publisher { json.set! '@id', person_id(@item.collector) }

    json.bornDigital @item.born_digital

    json.inLanguage do
      json.array! @item.content_languages do |language|
        json.set! '@id', language_id(language)
      end
    end

    json.countries do
      json.array! @item.countries do |country|
        json.set! '@id', country_id(country)
      end
    end

    json.digitisedOn @item.digitised_on
    json.external @item.external
    json.languageAsGiven @item.language
    json.metadataExportable @item.metadata_exportable
    json.originalMedia @item.original_media
    json.originatedOn @item.originated_on
    json.private @item.private

    json.subjectLanguages do
      json.array! @item.subject_languages do |language|
        json.set! '@id', language_id(language)
      end
    end
    json.tapesReturned @item.tapes_returned

    # json.about do
    #   json.set! '@id', rocrate_collection_item_url(@item)
    # end
    # json.conformsTo do
    #   json.set! '@id', 'https://w3id.org/ro/crate/1.2-DRAFT'
    # end
  end

  grouped_item_agents = @item.item_agents.group_by(&:user).map do |user, item_agents|
    data = { user:, roles: item_agents.map(&:agent_role) }
    data[:roles].push(OpenStruct.new({ name: 'collector' })) if user.id == @item.collector.id

    data
  end
  json.array! grouped_item_agents do |grouped_item_agent|
    person_json(json, grouped_item_agent[:user], grouped_item_agent[:roles])
  end

  json.array! @item.essences do |essence|
    essence_json(json, essence)
  end

  json.child! do
    access_condition_json(json, @item.access_condition)
  end

  json.child! do
    organisation_json(json, @item.university)
  end

  json.child! do
    rocrate_json(json)
  end

  roles = grouped_item_agents.map { |grouped_item_agent| grouped_item_agent[:roles] }.flatten.uniq
  json.array! roles do |role|
    role_json(json, role)
  end
end
# rubocop:enable Metrics/BlockLength
