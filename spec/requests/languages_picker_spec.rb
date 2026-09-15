require 'rails_helper'

# The /languages endpoint backs every language picker: item, collection, bulk-edit and advanced-search forms.
describe 'Languages picker', type: :request do
  let!(:mul) { create(:language, code: 'mul', name: 'Multiple languages') }
  let!(:und) { create(:language, code: 'und', name: 'Undetermined') }
  let!(:zxx) { create(:language, code: 'zxx', name: 'No linguistic content') }

  before { sign_in create(:user) }

  def picker(params)
    get languages_path, params: params

    response.parsed_body['results']
  end

  def picker_labels(params)
    picker(params).map { |result| result['label'] }
  end

  describe 'a name shared across sources' do
    before do
      create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri')
      create(:language, :glottolog_dialect, code: 'laja1237', name: 'Lajamanu Warlpiri')
      create(:language, :austlang, code: 'C15', name: 'Warlpiri')
      create(:language, code: 'wbp', name: 'Warlpiri')
      create(:language, code: 'wrp', name: 'Old Warlpiri', retired: true)
    end

    it 'reads each hit as its Label, ISO then Glottolog then AUSTLANG, then dialects, then retired' do
      expect(picker_labels(q: 'Warlpiri')).to eq(
        [
          'Warlpiri (wbp) · ISO 639-3',
          'Warlpiri (warl1254) · Glottolog',
          'Warlpiri (C15) · AUSTLANG',
          'Lajamanu Warlpiri (laja1237) · Glottolog dialect',
          'Old Warlpiri (wrp) · ISO 639-3',
          'Multiple languages (mul) · ISO 639-3',
          'Undetermined (und) · ISO 639-3',
          'No linguistic content (zxx) · ISO 639-3'
        ]
      )
    end

    it 'marks only the retired hit as retired' do
      described = picker(q: 'Warlpiri').select { |result| result['description'] }

      expect(described.to_h { |result| [result['label'], result['description']] }).to eq('Old Warlpiri (wrp) · ISO 639-3' => 'Retired')
    end

    it 'ranks an exact code match first' do
      expect(picker_labels(q: 'C15').first).to eq('Warlpiri (C15) · AUSTLANG')
      expect(picker_labels(q: 'laja1237').first).to eq('Lajamanu Warlpiri (laja1237) · Glottolog dialect')
    end
  end

  it 'ranks an exact code match ahead of names that merely contain it' do
    create(:language, code: 'akb', name: 'Akabu')
    create(:language, code: 'kab', name: 'Kabardian')

    expect(picker_labels(q: 'kab').first(2)).to eq(['Kabardian (kab) · ISO 639-3', 'Akabu (akb) · ISO 639-3'])
  end

  it 'returns twenty hits for a common name, then the three special codes' do
    create_list(:language, 25, name: 'Common tongue') # rubocop:disable FactoryBot/ExcessiveCreateList

    labels = picker_labels(q: 'Common')

    expect(labels.size).to eq(23)
    expect(labels.first(20)).to all(start_with('Common tongue'))
    expect(labels.last(3)).to eq(
      ['Multiple languages (mul) · ISO 639-3', 'Undetermined (und) · ISO 639-3', 'No linguistic content (zxx) · ISO 639-3']
    )
  end

  it 'appends the special codes from ISO 639-3 only once, even when they match the query' do
    labels = picker_labels(q: 'und')

    expect(labels.count('Undetermined (und) · ISO 639-3')).to eq(1)
  end

  it 'narrows to the chosen countries for every source' do
    australia = create(:country, name: 'Australia')
    vanuatu = create(:country, name: 'Vanuatu')
    glottolog = create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri')
    austlang = create(:language, :austlang, code: 'C15', name: 'Warlpiri')
    elsewhere = create(:language, code: 'wbp', name: 'Warlpiri')
    CountriesLanguage.create!(country: australia, language: glottolog)
    CountriesLanguage.create!(country: australia, language: austlang)
    CountriesLanguage.create!(country: vanuatu, language: elsewhere)

    ids = picker(q: 'Warlpiri', country_ids: [australia.id]).map { |result| result['value'] }

    expect(ids).to eq([glottolog.id, austlang.id, mul.id, und.id, zxx.id])
  end
end
