require 'rails_helper'

# OLAC's vocabulary is ISO 639 only: olac:code is typed to the ISO 639 shape, so a glottocode or an
# AUSTLANG code in that attribute is a schema violation. A Language from either of those Sources is
# therefore emitted as text naming its own Source, and never through an Equivalent's ISO code.
describe 'OAI-PMH language identity', :no_catalog_upload, type: :request do
  let(:iso) { create(:language, code: 'wbp', name: 'Warlpiri') }
  let(:glottolog) { create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri') }
  let(:austlang) { create(:language, :austlang, code: 'C15', name: 'Warlpiri') }
  let(:retired_iso) { create(:language, code: 'wbq', name: 'Waddar', retired: true) }

  describe 'GET /oai/item in OLAC' do
    def olac_body(subject_languages: [], content_languages: [])
      create(:item, subject_languages:, content_languages:)
      get '/oai/item', params: { verb: 'ListRecords', metadataPrefix: 'olac' }

      expect(response).to have_http_status(:ok)
      response.body
    end

    def elements(body, name)
      Nokogiri::XML(body).xpath("//dc:#{name}", dc: 'http://purl.org/dc/elements/1.1/')
    end

    # olac:code and xsi:type are namespaced, so neither answers to a plain attribute lookup.
    def olac_code(node)
      node.attribute_with_ns('code', 'http://www.language-archives.org/OLAC/1.1/')&.value
    end

    def xsi_type(node)
      node.attribute_with_ns('type', 'http://www.w3.org/2001/XMLSchema-instance')&.value
    end

    it 'validates against the vendored OLAC schemas for a Language from every Source' do
      body = olac_body(subject_languages: [iso, glottolog], content_languages: [austlang, retired_iso])

      expect(olac_schema_errors(body)).to be_empty
    end

    it 'keeps the ISO 639-3 code in the typed attribute' do
      body = olac_body(content_languages: [iso])
      language = elements(body, 'language').find { |node| olac_code(node) == 'wbp' }

      expect(language).to be_present
      expect(xsi_type(language)).to eq('olac:language')
    end

    it 'emits a retired ISO row exactly as a current one' do
      body = olac_body(content_languages: [retired_iso])

      expect(elements(body, 'language').map { |node| olac_code(node) }).to include('wbq')
    end

    it 'emits a Glottolog Language as text naming its Source' do
      body = olac_body(content_languages: [glottolog])
      language = elements(body, 'language').find { |node| node.text.include?('warl1254') }

      expect(language).to be_present
      expect(language.text).to eq('Warlpiri [glottolog:warl1254]')
    end

    it 'emits an AUSTLANG Language as text naming its Source' do
      body = olac_body(subject_languages: [austlang])
      subject_element = elements(body, 'subject').find { |node| node.text.include?('C15') }

      expect(subject_element).to be_present
      expect(subject_element.text).to eq('Warlpiri [austlang:C15]')
    end

    it 'gives a non-ISO Language no code attribute of any kind' do
      body = olac_body(subject_languages: [glottolog], content_languages: [austlang])
      non_iso = (elements(body, 'language') + elements(body, 'subject')).select { |node| node.text.include?('[') }

      expect(non_iso.size).to eq(2)
      expect(non_iso.map { |node| olac_code(node) }).to all(be_nil)
      expect(non_iso.map { |node| xsi_type(node) }).to all(be_nil)
    end
  end

  # ARDC's subject vocabulary has a token for ISO 639 and none for Glottolog or AUSTLANG, so every
  # Source is named as a local subject and only an ISO row also carries its code.
  describe 'GET /oai/collection in RIF-CS' do
    def rif_document(languages)
      create(:collection, languages:)
      get '/oai/collection', params: { verb: 'ListRecords', metadataPrefix: 'rif' }

      expect(response).to have_http_status(:ok)
      Nokogiri::XML(response.body).remove_namespaces!
    end

    def subjects(document, type)
      document.xpath("//subject[@type='#{type}']").map(&:text)
    end

    it 'names every Source as a local subject' do
      document = rif_document([iso, glottolog, austlang])

      expect(subjects(document, 'local')).to contain_exactly('Warlpiri', 'Warlpiri', 'Warlpiri')
    end

    it 'gives the code as an iso639 subject for an ISO row only' do
      document = rif_document([iso, glottolog, austlang])

      expect(subjects(document, 'iso639')).to eq(['wbp'])
    end

    it 'no longer uses the iso639-3 subject type ARDC does not publish' do
      document = rif_document([iso])

      expect(subjects(document, 'iso639-3')).to be_empty
    end

    it 'relates every Source to its own website' do
      document = rif_document([iso, glottolog, austlang])
      related = document.xpath("//relatedInfo[@type='website']")
      pairs = related.map { |node| [node.at_xpath('identifier').text, node.at_xpath('title').text] }

      expect(pairs).to include(
        ['https://iso639-3.sil.org/code/wbp', 'ISO 639-3 entry for Warlpiri'],
        ['https://glottolog.org/resource/languoid/id/warl1254', 'Glottolog entry for Warlpiri'],
        ['https://collection.aiatsis.gov.au/austlang/language/C15', 'AUSTLANG entry for Warlpiri']
      )
    end

    it 'leaves no Ethnologue link behind' do
      create(:collection, languages: [iso, glottolog, austlang])
      get '/oai/collection', params: { verb: 'ListRecords', metadataPrefix: 'rif' }

      expect(response.body).not_to include('ethnologue.com')
    end
  end
end
