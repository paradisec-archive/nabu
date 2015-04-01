require 'spec_helper'
describe 'Item Search', search: true do
  let!(:country1) {create(:country)}
  let!(:country2) {create(:country)}
  let!(:item1) {create(:item, countries: [country1])}
  let!(:item2) {create(:item, countries: [country2])}

  let!(:user) {create(:user)}

  before(:all) do
    Sunspot.remove_all!(Item)
    Sunspot.index!(item1, item2)
  end

  context 'when user is not signed in' do
    context 'viewing the page' do
      before do
        visit search_items_path
      end
      it 'should not show advanced search' do
        expect(page).to_not have_content('Advanced Search')
      end
      it 'should show all items' do
        expect(page).to_not have_content('NO results')
        expect(page).to have_content(item1.identifier)
      end
    end
  end

  context 'when user is signed in' do
    before do
      login_as user, scope: :user
      visit search_items_path
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
          uri += "#{uri.include?('?') ? '&' : '?'}country_id=#{country1.id}"

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
            fill_in 'search', with: item2.identifier
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
  end
end