require 'rails_helper'

# Wherever a person reads a Language in Nabu's own pages and feeds, it reads as the Label and links to the Source URI.
describe 'Language rendering', type: :request do
  let(:iso) { create(:language, code: 'wbp', name: 'Warlpiri') }
  let(:glottolog) { create(:language, :glottolog_dialect, code: 'laja1237', name: 'Lajamanu Warlpiri') }
  let(:austlang) { create(:language, :austlang, code: 'C15', name: 'Warlpiri') }
  let(:collection) { create(:collection, languages: [iso, glottolog, austlang]) }
  let!(:item) { create(:item, collection:, subject_languages: [glottolog, austlang], content_languages: [iso]) }

  let(:linked_labels) do
    {
      'Warlpiri (wbp) · ISO 639-3' => 'https://iso639-3.sil.org/code/wbp',
      'Lajamanu Warlpiri (laja1237) · Glottolog dialect' => 'https://glottolog.org/resource/languoid/id/laja1237',
      'Warlpiri (C15) · AUSTLANG' => 'https://collection.aiatsis.gov.au/austlang/language/C15'
    }
  end

  def language_links
    response.parsed_body.css('a').to_h { |link| [link.text.strip, link['href']] }
  end

  describe 'show pages' do
    before { sign_in create(:admin_user) }

    it 'links each of a collection’s languages from its Label to its Source URI' do
      get collection_path(collection)

      expect(language_links).to include(linked_labels)
    end

    it 'links each of an item’s languages from its Label to its Source URI' do
      get collection_item_path(collection, item)

      expect(language_links).to include(linked_labels)
      expect(response.body).not_to include('language-archives.org/language')
    end
  end

  describe 'item bulk edit', :search do
    before do
      item.reindex(refresh: true)
      sign_in create(:admin_user)
    end

    it 'offers each tagged language for deletion by its Label' do
      get bulk_update_items_path(full_identifier: item.full_identifier)

      form = response.parsed_body
      subject_options = form.css('#item_bulk_delete_subject_language_ids option').map(&:text).compact_blank
      content_options = form.css('#item_bulk_delete_content_language_ids option').map(&:text).compact_blank

      expect(subject_options).to contain_exactly('Lajamanu Warlpiri (laja1237) · Glottolog dialect', 'Warlpiri (C15) · AUSTLANG')
      expect(content_options).to eq(['Warlpiri (wbp) · ISO 639-3'])
    end
  end

  describe 'GeoJSON feeds' do
    it 'names a collection’s languages by their Labels' do
      get collections_path(format: :geo_json)

      feature = JSON.parse(response.body)['features'].first

      expect(feature['properties']['languages']).to eq(
        'Warlpiri (wbp) · ISO 639-3, Lajamanu Warlpiri (laja1237) · Glottolog dialect, Warlpiri (C15) · AUSTLANG'
      )
    end

    it 'names an item’s subject languages by their Labels' do
      get collection_path(collection, format: :geo_json)

      feature = JSON.parse(response.body)['features'].first

      expect(feature['properties']['languages']).to eq('Lajamanu Warlpiri (laja1237) · Glottolog dialect, Warlpiri (C15) · AUSTLANG')
    end
  end
end
