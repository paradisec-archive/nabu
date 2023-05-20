require 'rails_helper'

describe 'Item Search', search: true do
  describe 'Solr searching of items' do
    let(:search) do
      Item.solr_search do
        fulltext search_term
      end
    end

    before(:each) do
      # Ensure that full_identifier can't be confused with identifier
      # FIXME: JF bring this back later - issue with stubbing
      # item.stub(:full_identifier) { (item.collection.identifier + '-' + item.identifier).tr('a-yA-Y0-8', 'b-zB-Z1-9') }
      # fail "Full identifier #{item.full_identifier}, identifier #{item.identifier}" if item.full_identifier.include?(item.identifier)
      Sunspot.remove_all!(Item)
      Sunspot.index!(item)
    end

    context 'searching by a keyword mentioned in language' do
      let(:language) { 'South Efate, Bislama' }
      let(:item) { create(:item, language: language) }
      let(:search_term) { language }
      it 'should have a match' do
        expect(search.results.length).to eq 1
      end
    end

    context 'searching by item identifier' do
      let(:identifier) { 'SomeWords' }
      let(:item) { create(:item, identifier: identifier) }

      context 'search term is longer than 10 characters' do
        let(:identifier) { 'ReallyLongWord' }
        let(:item) { create(:item, identifier: identifier) }

        context 'using a full keyword' do
          let(:search_term) { identifier }
          it 'should have a match' do
            expect(search.results.length).to eq 1
          end
        end

        context 'using a partial keyword' do
          let(:search_term) { identifier[0..-2] }
          it 'should have a match' do
            expect(search.results.length).to eq 1
          end
        end
      end

      context 'using a full keyword' do
        let(:search_term) { identifier }
        it 'should have a match' do
          expect(search.results.length).to eq 1
        end
      end

      context 'using a partial keyword' do
        let(:search_term) { identifier[0..-2] }
        it 'should have a match' do
          expect(search.results.length).to eq 1
        end
      end
    end

    context 'searching by full identifier' do
      let(:identifier) { 'House' }
      let(:item) { create(:item, identifier: identifier) }

      context 'search term is longer than 10 characters' do
        let(:identifier) { 'ReallyLongWord' }
        let(:item) { create(:item, identifier: identifier) }

        context 'using a full keyword' do
          let(:search_term) { item.full_identifier }
          it 'should have a match' do
            expect(search.results.length).to eq 1
          end
        end

        context 'using a partial keyword' do
          let(:search_term) { item.full_identifier[0..-2] }
          it 'should have a match' do
            expect(search.results.length).to eq 1
          end
        end
      end

      context 'using a full keyword' do
        let(:search_term) { item.full_identifier }
        it 'should have a match' do
          expect(search.results.length).to eq 1
        end
      end

      context 'using a partial keyword' do
        let(:search_term) { item.full_identifier[0..-2] }
        it 'should have a match' do
          expect(search.results.length).to eq 1
        end
      end
    end
  end

  describe 'ItemsController use of Item Search' do
    let!(:country1) {create(:country)}
    let!(:country2) {create(:country)}
    let!(:item1) {create(:item, countries: [country1])}
    let!(:item2) {create(:item, countries: [country2])}

    let!(:user) {create(:user)}

    before(:each) do
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

            click_link 'Clear'

            expect(page).to have_content(country2.name)

            expect(URI.parse(current_url).request_uri).to end_with('search') # no query params
          end
        end
      end
    end
  end
end
