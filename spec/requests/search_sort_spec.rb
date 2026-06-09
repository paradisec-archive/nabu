require 'rails_helper'

# Regression coverage for the production OpenSearch sort errors (query_shard_exception)
# raised when sorting on a field not mapped in the index.
describe 'Search sorting', :no_catalog_upload, :search, type: :request do
  let!(:country) { create(:country) }
  let!(:language) { create(:language) }
  let!(:collection) { create(:collection, :reindex, countries: [country], languages: [language]) }
  let!(:item) { create(:item, :reindex, collection:, countries: [country]) }

  describe 'collections search' do
    it 'renders results when given a valid sort column' do
      get search_collections_path(sort: 'updated_at', direction: 'desc')

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(collection.identifier)
      end
    end

    it 'ignores an unknown sort field rather than raising a query_shard_exception' do
      get search_collections_path(sort: 'no_such_field', direction: 'asc')

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(collection.identifier)
      end
    end

    it 'ignores a malicious sort payload' do
      get search_collections_path(sort: 'title; DROP TABLE collections', direction: 'desc')

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'items search' do
    # Item search requires authentication (unlike collection search)
    before { sign_in create(:user) }

    it 'renders results when given a valid sort column' do
      get search_items_path(sort: 'created_at', direction: 'desc')

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(item.full_identifier)
      end
    end

    it 'ignores an unknown sort field' do
      get search_items_path(sort: 'no_such_field', direction: 'asc')

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(item.full_identifier)
      end
    end
  end
end
