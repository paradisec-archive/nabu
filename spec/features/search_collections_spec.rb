require 'spec_helper'
describe 'Collection Search', search: true do
  let!(:country1) {create(:country)}
  let!(:country2) {create(:country)}
  let!(:language) {create(:language)}
  let!(:collection1) {create(:collection, countries: [country1], languages: [language])}
  let!(:collection2) {create(:collection, countries: [country2], languages: [language])}
  let!(:private_collection) {create(:collection, countries: [country1], languages: [language], private: true)}
  let!(:user) {create(:user)}

  before(:each) do
    Sunspot.remove_all(Collection)
    Sunspot.index!(collection1, collection2, private_collection)
  end

  context 'when user is not signed in' do
    context 'viewing the page' do
      before do
        visit search_collections_path
      end
      it 'should not show advanced search' do
        expect(page).to_not have_content('Advanced Search')
      end
      it 'should show all collections' do
        expect(page).to_not have_content('NO results')
        expect(page).to have_content(collection1.identifier)
      end
    end
  end

  context 'when user is signed in' do
    before do
      login_as user, scope: :user
      visit search_collections_path
    end

    context 'viewing the page' do
      it 'should show advanced search' do
        expect(page).to have_content('Advanced Search')
      end
    end
    context 'running a search' do
      context 'when selecting from the filter lists' do
        it 'should filter other lists as well' do
          uri = URI.parse(current_url).request_uri.to_s
          uri += "#{uri.include?('?') ? '&' : '?'}country_code=#{country1.code.gsub(' ', '+')}"

          expect(page).to have_content(country2.name)

          click_link country1.name

          expect(URI.parse(current_url).request_uri).to eq(uri)
          expect(page).to_not have_content(country2.name)
        end
        it 'should perform search immediately' do
          expect(page).to have_content('2 search results')

          click_link country1.name

          expect(page).to have_content('1 search result')
        end
      end
      context 'when searching by keyword' do
        #TODO: Fix this so that the required: true on the page actually stops this, rather than getting bypassed
        # context 'with no value' do
        #   it 'should maintain current search' do
        #     click_link country1.name
        #     expect(page).to_not have_content(country2.name)
        #
        #     fill_in 'search', with: nil
        #     click_button 'Search'
        #
        #     expect(page).to_not have_content(country2.name)
        #   end
        # end
        context 'with a value' do
          it 'should remove facet filters' do
            click_link country1.name
            expect(page).to_not have_content(country2.name)
            fill_in 'search', with: collection2.identifier
            click_button 'Search'
            sleep 1

            expect(page).to have_content(country2.name)
            expect(page).to_not have_content(country1.name)
          end
        end
      end
      context 'when clearing the search' do
        it 'should remove all params and reset search' do
          expect(page).to have_content(country2.name)

          click_link country1.name

          expect(page).to_not have_content(country2.name)

          click_button 'Clear'

          expect(page).to have_content(country2.name)

          expect(URI.parse(current_url).request_uri).to end_with('search') # no query params
        end
      end
    end

    describe 'private collection' do
      context 'normal user' do
        # No need to change user

        it 'cannot be viewed by the user' do
          expect(page).to_not have_content(private_collection.identifier)
        end
      end

      context 'user is an admin' do
        let!(:user) { create(:admin_user) }

        it 'can be viewed by the user' do
          expect(page).to have_content(private_collection.identifier)
        end
      end

      context 'user has edit rights' do
        let!(:private_collection) {create(:collection, countries: [country1], languages: [language], private: true, admins: [user])}

        it 'can be viewed by the user' do
          expect(page).to have_content(private_collection.identifier)
        end
      end
    end
  end
end