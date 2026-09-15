require 'rails_helper'

describe 'Collections' do
  let(:user) { create(:user) }
  let(:admin_user) { create(:admin_user) }

  before do
    create(:university)
    create(:country)
    create(:language)
    create(:field_of_research)
  end

  describe 'Creating' do
    it 'fails as a guest' do
      visit root_path
      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_no_text('Add collection')
      visit new_collection_path
      expect(page).to have_text('You need to sign in or sign up before continuing')
    end

    it 'succeeds as user' do
      sign_in admin_user
      visit root_path
      expect(page).to have_text('Add new collection')
      click_on 'Add new collection'
      expect(page).to have_text('Deposit form received')
    end

    # it 'create collection', :js => true do
    #   pending 'INVESTIGATE 2016-05-09: Failing on development machines'
    #   sign_in admin_user
    #   visit new_collection_path
    #   fill_in 'Collection ID', :with => 'AAA'
    #   fill_in 'collection_title', :with => 'Alexander Adelaar Indonesia/Selaako Collection'
    #   select university.name, :from => 'Originating university'
    #   select field_of_research.name_with_identifier, :from => 'Field of research'
    #   select2_ajax admin_user.id, from: 'Collector'
    #   fill_in 'Region / village', with: 'Sasak Village, Samalantan'
    #   fill_in 'Description', :with => 'This collection is awesome\nMoo'
    #   select2_ajax country.id, :from => 'Countries'
    #   select2_ajax language.id, :from => 'Languages'
    #   within '.first' do
    #     click_on 'Add Collection'
    #   end
    #
    #   expect(page).to have_content('Collection was successfully created.')
    # end
  end
end
