require 'spec_helper'

describe 'Collections' do
  let(:user) { create :user }
  let(:admin_user) { create :admin_user }
  let!(:university) { create :university, :name => 'University of Sydney' }
  let!(:country) { create :country, :name => 'Indonesia', :code => 'ID' }
  let!(:language) { create :language, :name => 'Silka', :code => 'ski' }
  let!(:field_of_research) { create :field_of_research, :name => 'Indonesian Languages', :identifier => '420114' }

  describe 'Creating' do
    it 'should fail as a guest' do
      visit root_path
      page.should_not have_content('Add collection')
      visit new_collection_path
      page.should have_content('You need to sign in or sign up before continuing')
    end

    it 'should succeed as user' do
      login user
      visit dashboard_path
      page.should have_content('Add new collection')
      click_on 'Add new collection'
      page.should have_content('Deposit form received')
    end

    it 'create collection', :js => true do
      login user
      visit new_collection_path
      fill_in 'Collection ID', :with => 'AA1'
      fill_in 'collection_title', :with => 'Alexander Adelaar Indonesia/Selaako Collection'
      select 'University of Sydney', :from => 'Originating university'
      select '420114 - Indonesian Languages', :from => 'Field of research'
      select2_ajax 'Indonesia', :from => 'Choose a country...'
      select2_ajax 'ski - Silka', :from => 'Languages'
      fill_in 'Region / village', :with => 'Sasak Village, Samalantan'
      fill_in 'Description', :with => 'This collection is awesome\nMoo'
      within '.first' do
        click_on 'Add Collection'
      end

      page.should have_content('Collection was successfully created.')
    end
  end
end
