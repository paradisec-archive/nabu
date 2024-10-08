module IdentifiableByDoi
  extend ActiveSupport::Concern

  included do
    def to_doi_json(prefix)
      # NOTE: Items are the only type which contain the true publication date, so prefer that, but fall back to the date it was added to Nabu
      publication_date =
        if is_a?(Item)
          originated_on || created_at
        elsif is_a?(Essence)
          item.originated_on || created_at
        else
          created_at
        end

      parent =
        if is_a?(Item)
          collection
        elsif is_a?(Essence)
          item
        end

      resource_type = "PARADISEC #{self.class}"

      resource_type_general =
        if is_a?(Item)
          'Collection'
        elsif is_a?(Essence)
          essence_resource_type
        else
          'Collection'
        end

      contributors = [{ name: collector_name, contributorType: 'DataCollector' }]
      contributors.push({ name: university_name, contributorType: 'DataCollector' }) if respond_to?(:university_name) && university_name.present?

      attributes = {
        event: 'publish',
        prefix:,
        creators: [{ name: collector_name }],
        titles: [{ title: }],
        publisher: 'PARADISEC',
        publicationYear: publication_date.year.to_s,
        contributors:,
        url: full_path,
        identifiers: [{ identifier: full_path, identifierType: 'URL' }],
        types: {
          resourceType: resource_type,
          resourceTypeGeneral: resource_type_general
        },
        schemaVersion: 'http://datacite.org/schema/kernel-4'
      }

      # NOTE: parent should exist for everything except Collection
      if parent
        attributes['relatedIdentifiers'] = [{
          relatedIdentifier: parent.doi,
          relatedIdentifierType: 'DOI',
          relationType: is_a?(Item) ? 'IsPartOf' : 'IsSourceOf'
        }]
      end

      {
        data: {
          type: 'dois',
          attributes:
        }
      }.to_json
    end
  end

  private

  def essence_resource_type
    case mimetype.split('/')[0]
    when 'audio' then 'Sound'
    when 'video' then 'Audiovisual'
    when 'image' then 'Image'
    when 'text' then 'Text'
    else 'Other'
    end
  end
end
