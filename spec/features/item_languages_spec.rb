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

  it 'marks a retired language as retired on its chip, and keeps the mark when copied' do
    retired = create(:language, code: 'wrp', name: 'Old Warlpiri', retired: true)
    item.update!(content_languages: [retired])

    visit edit_collection_item_path(item.collection, item)
    click_on 'Copy from Content language'

    %w[Content Subject].each do |field|
      within(:xpath, "//label[contains(text(),'#{field} language')]/ancestor::tr") do
        expect(page).to have_css(".choices__list--multiple .choices__item[data-label-description='Retired']", text: retired.label)
      end
    end
  end
end
