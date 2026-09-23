require 'rails_helper'

# Every form that tags languages offers a tagged Language's Equivalents as one-click chips. The click itself
# happens in the browser; what the server owes the chips is the pairs, in evidence order, with their reasons.
describe 'Equivalent chips', type: :request do
  let(:iso) { create(:language, code: 'wbp', name: 'Warlpiri') }
  let(:glottolog) { create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri') }
  let(:austlang) { create(:language, :austlang, code: 'C15', name: 'Warlpiri') }
  let(:collection) { create(:collection, languages: [iso]) }
  let(:item) { create(:item, collection:, content_languages: [iso], subject_languages: [iso]) }

  let(:by_code) { 'Glottolog gives this ISO 639-3 code' }
  let(:by_name) { 'Both Sources publish the same name' }

  let(:iso_option) { { 'value' => iso.id, 'label' => 'Warlpiri (wbp) · ISO 639-3' } }
  let(:glottolog_option) { { 'value' => glottolog.id, 'label' => 'Warlpiri (warl1254) · Glottolog' } }
  let(:austlang_option) { { 'value' => austlang.id, 'label' => 'Warlpiri (C15) · AUSTLANG' } }

  # A chip adds a Language the picker was never asked for, so it carries that Language's own
  # Equivalents and its chips render in turn. One level only: a pair of a pair is two clicks.
  let(:glottolog_chip) do
    glottolog_option.merge('custom_properties' => { 'equivalents' => [iso_option.merge('reason' => by_code)] }, 'reason' => by_code)
  end
  let(:austlang_chip) do
    austlang_option.merge('custom_properties' => { 'equivalents' => [iso_option.merge('reason' => by_name)] }, 'reason' => by_name)
  end

  before do
    create(:language_equivalent, language: iso, related_language: austlang, evidence: ['name'])
    create(:language_equivalent, language: iso, related_language: glottolog, evidence: ['glottolog:iso'])
    sign_in create(:admin_user)
  end

  # Choices.js reads an option's Equivalents from its custom properties, and hands them back when the
  # chips ask what is tagged.
  def chips_on(selector, language)
    option = response.parsed_body.at_css("#{selector} option[value='#{language.id}']")

    JSON.parse(option['data-custom-properties'])['equivalents']
  end

  def chips_enabled_on?(selector)
    field = response.parsed_body.at_css(selector)

    field['data-equivalents'] == 'true' && response.parsed_body.at_css("##{field['id']}_equivalents").present?
  end

  describe 'the item form' do
    before { get edit_collection_item_path(collection, item) }

    it 'carries each tagged Language’s Equivalents, strongest evidence first, on both language fields' do
      expect(chips_on('select#item_content_language_ids', iso)).to eq([glottolog_chip, austlang_chip])
      expect(chips_on('select#item_subject_language_ids', iso)).to eq([glottolog_chip, austlang_chip])
    end

    it 'gives both language fields somewhere to render their chips' do
      expect(chips_enabled_on?('select#item_content_language_ids')).to be true
      expect(chips_enabled_on?('select#item_subject_language_ids')).to be true
    end

    it 'carries each chip’s own Equivalents, and stops one level down' do
      chip = chips_on('select#item_content_language_ids', iso).first
      offered = chip.dig('custom_properties', 'equivalents')

      expect(offered).to eq([iso_option.merge('reason' => by_code)])
      expect(offered.first).not_to have_key('custom_properties')
    end

    it 'leaves a Language with no Equivalent carrying nothing' do
      item.update!(content_languages: [create(:language, code: 'aaa', name: 'Ghotuo')])

      get edit_collection_item_path(collection, item)

      option = response.parsed_body.at_css('select#item_content_language_ids option')

      expect(option['data-custom-properties']).to be_nil
    end
  end

  describe 'the collection form' do
    before { get edit_collection_path(collection) }

    it 'carries the tagged Language’s Equivalents' do
      expect(chips_on('select#collection_language_ids', iso)).to eq([glottolog_chip, austlang_chip])
    end

    it 'gives the language field somewhere to render its chips' do
      expect(chips_enabled_on?('select#collection_language_ids')).to be true
    end
  end

  # Bulk edit renders the same partials, so this holds the wiring rather than a second code path.
  describe 'bulk edit', :search do
    before { item.reindex(refresh: true) }

    it 'gives the bulk-edit language fields somewhere to render their chips' do
      get bulk_update_items_path(full_identifier: item.full_identifier)

      expect(chips_enabled_on?('select#item_content_language_ids')).to be true
      expect(chips_enabled_on?('select#item_subject_language_ids')).to be true
    end
  end

  # The page runs a search as it renders, so the indices have to hold the collection and item.
  describe 'advanced search', :search do
    before { item }

    it 'offers no chips on the item form' do
      get advanced_search_items_path

      expect(response.body).not_to include('data-equivalents')
      expect(response.body).not_to include('data-custom-properties')
    end

    it 'offers no chips on the collection form' do
      get advanced_search_collections_path

      expect(response.body).not_to include('data-equivalents')
      expect(response.body).not_to include('data-custom-properties')
    end
  end

  describe 'the picker endpoint, which serves a Language added after the page loaded' do
    def hit_for(language, query)
      get languages_path, params: { q: query }

      response.parsed_body['results'].find { |result| result['value'] == language.id }
    end

    it 'carries each hit’s Equivalents in the same order and shape as the form' do
      expect(hit_for(iso, 'wbp')['custom_properties']).to eq('equivalents' => [glottolog_chip, austlang_chip])
    end

    it 'carries the pair from the other side too, with the other side’s own Equivalents on it' do
      offered = { 'equivalents' => [glottolog_option.merge('reason' => by_code), austlang_option.merge('reason' => by_name)] }

      expect(hit_for(glottolog, 'warl1254')['custom_properties']).to eq(
        'equivalents' => [iso_option.merge('custom_properties' => offered, 'reason' => by_code)]
      )
    end

    it 'carries nothing for a Language with no Equivalent' do
      alone = create(:language, code: 'aaa', name: 'Ghotuo')

      expect(hit_for(alone, 'Ghotuo')).not_to have_key('custom_properties')
    end
  end

  describe 'evidence order' do
    let(:chirila) { create(:language, :austlang, code: 'C99', name: 'Warlpiri Chirila') }
    let(:closest) { create(:language, :glottolog_dialect, code: 'laja1237', name: 'Lajamanu Warlpiri') }
    let(:retired) { create(:language, code: 'wrp', name: 'Old Warlpiri', retired: true) }

    before do
      create(:language_equivalent, language: iso, related_language: chirila, evidence: ['chirila:glottocode'])
      create(:language_equivalent, language: iso, related_language: closest, evidence: %w[name glottolog:closest_iso])
      create(:language_equivalent, language: iso, related_language: retired, evidence: ['name'])

      get edit_collection_item_path(collection, item)
    end

    it 'ranks the pairs by their strongest evidence and names that evidence as the reason' do
      chips = chips_on('select#item_content_language_ids', iso)

      expect(chips.map { |chip| chip['value'] }).to eq([glottolog.id, closest.id, chirila.id, austlang.id, retired.id])
      expect(chips.second).to include('reason' => 'Glottolog names this the closest ISO 639-3 code')
    end

    it 'marks a retired Equivalent, so a chip carries the mark with it' do
      chips = chips_on('select#item_content_language_ids', iso)

      expect(chips.last).to include('value' => retired.id, 'description' => 'Retired')
    end
  end

  describe 'a dialect placed only under its closest ISO code' do
    let(:dialect) { create(:language, :glottolog_dialect, code: 'laja1237', name: 'Lajamanu Warlpiri') }
    let(:named_dialect) { create(:language, :glottolog_dialect, code: 'warl1255', name: 'Warlpiri') }
    let(:closest_language) { create(:language, :glottolog, code: 'ngar1297', name: 'Ngardily') }

    before do
      create(:language_equivalent, language: iso, related_language: dialect, evidence: ['glottolog:closest_iso'])
      create(:language_equivalent, language: iso, related_language: named_dialect, evidence: %w[glottolog:closest_iso name])
      create(:language_equivalent, language: iso, related_language: closest_language, evidence: ['glottolog:closest_iso'])

      get edit_collection_item_path(collection, item)
    end

    def chip_for(language)
      chips_on('select#item_content_language_ids', iso).find { |chip| chip['value'] == language.id }
    end

    it 'is collapsed, so its chip waits behind the toggle' do
      expect(chip_for(dialect)).to include('collapsed' => true)
    end

    it 'is not collapsed when other evidence pairs it too' do
      expect(chip_for(named_dialect)).not_to have_key('collapsed')
    end

    it 'is not collapsed when Glottolog calls it a language' do
      expect(chip_for(closest_language)).not_to have_key('collapsed')
    end
  end

  describe 'a form completed by clicking the chips' do
    it 'keeps the tagged Language and both Equivalents on an item' do
      patch collection_item_path(collection, item), params: { item: { content_language_ids: [iso.id, glottolog.id, austlang.id] } }

      expect(item.reload.content_languages).to contain_exactly(iso, glottolog, austlang)
    end

    it 'keeps the tagged Language and both Equivalents on a collection' do
      patch collection_path(collection), params: { collection: { language_ids: [iso.id, glottolog.id, austlang.id] } }

      expect(collection.reload.languages).to contain_exactly(iso, glottolog, austlang)
    end
  end
end
