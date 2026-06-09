require 'rails_helper'

# These actions interpolate params[:sort]/params[:direction] into an ActiveRecord .order
# string. They are now whitelisted against the model's real column names so a malicious or
# unknown sort value is ignored rather than injected into SQL.
describe 'Sort parameter hardening', :no_catalog_upload, type: :request do
  let!(:user) { create(:admin_user) }
  let!(:collection) { create(:collection, collector: user) }
  let!(:item) { create(:item, collection:, collector: user) }

  before { sign_in user }

  describe 'collection show' do
    it 'sorts items by a valid column' do
      get collection_path(collection, sort: 'identifier', direction: 'desc')

      expect(response).to have_http_status(:ok)
    end

    it 'ignores a SQL injection attempt in the sort param' do
      get collection_path(collection, sort: "identifier'); DROP TABLE items;--", direction: 'desc')

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(Item.exists?(item.id)).to be(true)
      end
    end

    it 'ignores an invalid direction' do
      get collection_path(collection, sort: 'identifier', direction: 'sideways')

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'dashboard' do
    it 'sorts collections by a valid column' do
      get root_path(sort: 'created_at', direction: 'asc')

      expect(response).to have_http_status(:ok)
    end

    it 'ignores a SQL injection attempt in the sort param' do
      get root_path(sort: "created_at'); DROP TABLE collections;--", direction: 'desc')

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(Collection.exists?(collection.id)).to be(true)
      end
    end
  end
end
