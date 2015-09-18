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
      xml.tag! 'publisher', collector_name
      xml.tag! 'publicationYear', created_at.year
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