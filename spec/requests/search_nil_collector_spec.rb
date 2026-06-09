require 'rails_helper'

# Regression coverage for the production NoMethodError ("undefined method 'name' for nil")
# raised in the search result views. There is no FK on collector_id, so a deleted user
# leaves collection.collector / item.collector == nil.
describe 'Search with a dangling collector', :no_catalog_upload, :search, type: :request do
  let!(:country) { create(:country) }
  let!(:language) { create(:language) }
  let!(:collection) { create(:collection, :reindex, countries: [country], languages: [language]) }
  let!(:item) { create(:item, :reindex, collection:, countries: [country]) }

  it 'renders the collections results when a collection has a deleted collector' do
    User.where(id: collection.collector_id).delete_all

    get search_collections_path

    expect(response).to have_http_status(:ok)
  end

  it 'renders the items results when an item has a deleted collector' do
    # Item search requires authentication (unlike collection search)
    sign_in create(:user)
    User.where(id: item.collector_id).delete_all

    get search_items_path

    expect(response).to have_http_status(:ok)
  end
end
