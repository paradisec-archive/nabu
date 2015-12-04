module IdentifiableByDoi
  def to_doi_xml
    xml = ::Builder::XmlMarkup.new
    xml.tag! 'resource', schema_definitions do
      xml.tag! 'creators' do
        xml.tag! 'creator' do
          xml.tag! 'creatorName', collector_name
        end
      end
      #TODO: replace with NABU/Paradisec identifier key
      xml.tag! 'identifier', '10.5072/00/bcndhj78437hjk', identifierType: 'DOI'
      xml.tag! 'titles' do
        xml.tag! 'title', title
      end
      xml.tag! 'publisher', 'PARADISEC'
      # Items are the only type which contain the true publication date, so prefer that, but fall back to the date it was added to Nabu
      xml.tag! 'publicationYear', (respond_to?(:originated_on) ? try(:originated_on) : created_at).year

      xml.tag! 'contributors' do
        xml.tag! 'contributor', contributorType: 'DataCollector' do
          xml.tag! 'contributorName', collector_name
        end

        if respond_to?(:university_name)
          xml.tag! 'contributor', contributorType: 'DataCollector' do
            xml.tag! 'contributorName', university_name
          end
        end
      end

      # parent should exist for everything except Collection
      if parent.present?
        xml.tag! 'relatedIdentifiers' do
          xml.tag! 'relatedIdentifier', parent.doi, relatedIdentifierType: 'DOI', relationType: is_a?(Item) ? 'IsPartOf' : 'IsSourceOf'
        end
      end
    end
  end

  private

  def schema_definitions
    {
      'xmlns'  => 'http://datacite.org/schema/kernel-3',
      'xmlns:xsi'     => 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation' => 'http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd'
    }
  end
end