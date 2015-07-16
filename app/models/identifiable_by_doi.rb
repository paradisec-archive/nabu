module IdentifiableByDoi
  def to_doi_xml
    xml = ::Builder::XmlMarkup.new
    xml.tag! 'resource', schema_definitions do
      xml.tag! 'creators' do
        xml.tag! 'creator' do
          xml.tag! 'creatorName', collector_name
        end
      end
      xml.tag! 'url', full_path
      xml.tag! 'titles' do
        xml.tag! 'title', title
      end
      xml.tag! 'publisher', 'Paradisec'
      xml.tag! 'publicationYear', '2015'
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