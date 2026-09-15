require 'rails_helper'

describe 'Collection Search', :search, type: :system do
  let!(:country1) { create(:country) }
  let!(:country2) { create(:country) }
  let!(:language) { create(:language) }
  let!(:collection2) { create(:collection, :reindex, countries: [country2], languages: [language]) }
  let!(:private_collection) { create(:collection, :reindex, countries: [country1], languages: [language], private: true) }
  let!(:user) { create(:user) }

  # Background public collection so the country1/language facets appear for signed-in users.
  before { create(:collection, :reindex, countries: [country1], languages: [language]) }

  context 'when user is not signed in' do
    it 'redirects to the login page' do
      visit search_collections_path
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  context 'when user is signed in' do
    before do
      sign_in user
      visit search_collections_path
    end

    context 'viewing the page' do
      it 'shows advanced search' do
        expect(page).to have_text('Advanced Search')
      end
    end

    context 'running a search' do
      context 'when selecting from the filter lists' do
        it 'filters other lists as well' do
          uri = URI.parse(current_url).request_uri.to_s
          uri += "#{uri.include?('?') ? '&' : '?'}countries=#{country1.name.gsub(' ', '+')}"

          expect(page).to have_text(country2.name)

          click_link country1.name

          expect(URI.parse(current_url).request_uri).to eq(uri)
          expect(page).to have_no_text(country2.name)
        end

        it 'performs search immediately' do
          expect(page).to have_text('2 search results')

          click_link country1.name

          expect(page).to have_text('1 search result')
        end
      end

      context 'when searching by keyword' do
        # TODO: Fix this so that the required: true on the page actually stops this, rather than getting bypassed
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
          it 'removes facet filters' do
            click_link country1.name
            expect(page).to have_no_text(country2.name)
            fill_in 'search', with: collection2.identifier
            click_button 'Search'

            expect(page).to have_text(country2.name)
            expect(page).to have_no_text(country1.name)
          end
        end
      end

      context 'when clearing the search' do
        it 'removes all params and reset search' do
          expect(page).to have_text(country2.name)

          click_link country1.name

          expect(page).to have_no_text(country2.name)

          click_link 'Clear'

          expect(page).to have_text(country2.name)

          expect(URI.parse(current_url).request_uri).to end_with('search') # no query params
        end
      end
    end

    describe 'private collection' do
      context 'normal user' do
        # No need to change user

        it 'cannot be viewed by the user' do
          expect(page).to have_no_text(private_collection.identifier)
        end
      end

      context 'user is an admin' do
        let!(:user) { create(:admin_user) }

        it 'can be viewed by the user' do
          expect(page).to have_text(private_collection.identifier)
        end
      end

      context 'user has edit rights' do
        let!(:private_collection) { create(:collection, :reindex, countries: [country1], languages: [language], private: true, admins: [user]) }

        # Re-visit after the override collection (with its admin grant) exists and is indexed;
        # the ancestor `before` rendered the page before this fixture was created.
        before { visit search_collections_path }

        it 'can be viewed by the user' do
          expect(page).to have_text(private_collection.identifier)
        end
      end
    end
  end

  describe 'the language facet' do
    let(:iso) { create(:language, name: 'Warlpiri', code: 'wbp') }
    let(:glottolog) { create(:language, :glottolog, name: 'Warlpiri', code: 'warl1254') }
    let!(:iso_collection) { create(:collection, :reindex, languages: [iso]) }
    let!(:glottolog_collection) { create(:collection, :reindex, languages: [glottolog]) }

    before do
      login_as user, scope: :user
      visit search_collections_path
    end

    it 'lists each Language by its Label, keeping same-named Sources apart' do
      within '#facets' do
        expect(page).to have_link('Warlpiri (wbp) · ISO 639-3')
        expect(page).to have_link('Warlpiri (warl1254) · Glottolog')

        click_link 'Warlpiri (warl1254) · Glottolog'
      end

      expect(page).to have_text('1 search result')
      expect(page).to have_text(glottolog_collection.identifier)
      expect(page).to have_no_text(iso_collection.identifier)
    end

    it 'still finds collections by a free-text search for the language name' do
      fill_in 'search', with: 'Warlpiri'
      click_button 'Search'

      expect(page).to have_text('2 search results')
    end
  end
end
