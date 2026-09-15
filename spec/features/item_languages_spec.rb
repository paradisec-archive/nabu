require 'rails_helper'

describe 'Tagging an item with languages', :js do
  let(:item) { create(:item) }
  let!(:dialect) { create(:language, :glottolog_dialect, code: 'laja1237', name: 'Lajamanu Warlpiri') }
  let!(:variety) { create(:language, :austlang, code: 'C15', name: 'Warlpiri') }

  before { sign_in create(:admin_user) }

  it 'shows a Glottolog dialect and an AUSTLANG variety as Label chips and saves both' do
    visit edit_collection_item_path(item.collection, item)
    choices_ajax dialect.label, from: 'Content language', minlength: 4
    choices_ajax variety.label, from: 'Content language', minlength: 4

    within(:xpath, "//label[contains(text(),'Content language')]/ancestor::tr") do
      expect(page).to have_css('.choices__list--multiple .choices__item', text: dialect.label)
      expect(page).to have_css('.choices__list--multiple .choices__item', text: variety.label)
    end

    first(:button, 'Save item').click

    expect(page).to have_current_path(collection_item_path(item.collection, item))
    expect(page).to have_text('Item was successfully updated.')
    expect(item.reload.content_languages).to include(dialect, variety)
  end
end
