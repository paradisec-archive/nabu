require 'rails_helper'

describe 'Oni search language facet', :no_catalog_upload, :search, type: :request do
  let(:search_path) { '/api/v1/oni/search' }
  let(:collection) { create(:collection, :reindex) }
  let(:iso) { create(:language, name: 'Warlpiri', code: 'wbp') }
  let(:glottolog) { create(:language, :glottolog, name: 'Warlpiri', code: 'warl1254') }
  let(:dialect) { create(:language, :glottolog_dialect, name: 'Ngaliya', code: 'ngal1292') }
  let(:austlang) { create(:language, :austlang, name: 'Warlpiri', code: 'C15') }

  def language_buckets
    response.parsed_body.dig('facets', 'languages_with_code').to_h { |bucket| [bucket['name'], bucket['count']] }
  end

  def item_identifiers
    response.parsed_body['entities'].filter_map { |entity| entity.dig('identifiers', 'itemIdentifier') }
  end

  before do
    create(:item, :reindex, collection:, identifier: 'ISO', content_languages: [iso])
    create(:item, :reindex, collection:, identifier: 'GLOTTOLOG', content_languages: [glottolog])
    create(:item, :reindex, collection:, identifier: 'DIALECT', content_languages: [dialect])
    create(:item, :reindex, collection:, identifier: 'AUSTLANG', content_languages: [austlang])
  end

  it 'gives each Language its own bucket named by its Label' do
    post search_path, params: { query: '*', filters: { entity_type: ['Item'] } }

    expect(language_buckets).to eq(
      'Warlpiri (wbp) · ISO 639-3' => 1,
      'Warlpiri (warl1254) · Glottolog' => 1,
      'Ngaliya (ngal1292) · Glottolog dialect' => 1,
      'Warlpiri (C15) · AUSTLANG' => 1
    )
  end

  it 'returns only items tagged with the Language whose bucket is chosen' do
    post search_path, params: { query: '*', filters: { languages_with_code: ['Warlpiri (warl1254) · Glottolog'] } }

    expect(item_identifiers).to contain_exactly('GLOTTOLOG')
  end

  it 'caps the facet at 10,000 buckets' do
    Language.insert_all!(Array.new(10_001) { |n| { source: 'glottolog', code: format('m%03d%04d', n / 10_000, n % 10_000), name: "Many #{n}" } })
    many = Language.where('code LIKE ?', 'm00%').pluck(:id)
    item = create(:item, collection:, identifier: 'MANY', content_languages: [iso])
    ItemContentLanguage.insert_all!(many.map { |language_id| { item_id: item.id, language_id: } })
    item.reload.reindex(refresh: true)

    post search_path, params: { query: '*', filters: { entity_type: ['Item'] } }

    expect(language_buckets.size).to eq(10_000)
  end
end
