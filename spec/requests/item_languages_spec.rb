require 'rails_helper'

# A depositor can tag an item with a Language from any Source, and the form offers each one back by its Label.
describe 'Tagging an item with languages', type: :request do
  let(:item) { create(:item) }
  let!(:dialect) { create(:language, :glottolog_dialect, code: 'laja1237', name: 'Lajamanu Warlpiri') }
  let!(:variety) { create(:language, :austlang, code: 'C15', name: 'Warlpiri') }

  before { sign_in create(:admin_user) }

  it 'saves a Glottolog dialect and an AUSTLANG variety and offers both back as Labels' do
    patch collection_item_path(item.collection, item), params: { item: { content_language_ids: [dialect.id, variety.id] } }

    expect(item.reload.content_languages).to contain_exactly(dialect, variety)

    get edit_collection_item_path(item.collection, item)

    options = response.parsed_body.css('select.language#item_content_language_ids option').map(&:text)

    expect(options).to contain_exactly('Lajamanu Warlpiri (laja1237) · Glottolog dialect', 'Warlpiri (C15) · AUSTLANG')
  end
end
