require 'rails_helper'

# The Oni search spans the Collection, Item and Essence indices at once. Sorting on a field
# that is not mapped in every index (e.g. id, title/name) previously raised an OpenSearch
# query_shard_exception and returned HTTP 500. These now fall back to relevance (_score).
describe 'Oni search sorting', :no_catalog_upload, :search, type: :request do
  let(:search_path) { '/api/v1/oni/search' }

  before do
    collection = create(:collection, :reindex)
    create(:item, :reindex, collection:)
  end

  # All of these pass Oni::SearchValidator; id/name/title are not mapped across every index
  # so they must fall back to _score rather than erroring.
  %w[relevance name id title originated_on].each do |sort|
    it "returns 200 (not a query_shard_exception) when sorting by #{sort}" do
      post search_path, params: { query: '*', sort:, order: 'asc' }

      expect(response).to have_http_status(:ok)
    end
  end

  it 'still returns 422 for an entirely invalid sort field (validator rejects it)' do
    post search_path, params: { query: '*', sort: 'not_a_field' }

    expect(response).to have_http_status(:unprocessable_content)
  end
end
