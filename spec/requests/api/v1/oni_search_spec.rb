require 'rails_helper'

# The Oni search spans the Collection, Item and Essence indices at once. Sorting on a field
# that is not mapped in every index (e.g. id, title/name) previously raised an OpenSearch
# query_shard_exception and returned HTTP 500. title/name now sort on the downcased title_sort
# field, id on the number-aware full_identifier_sort, and created_at/updated_at on their date
# fields, all mapped across all three indices; relevance falls back to _score.
describe 'Oni search sorting', :no_catalog_upload, :search, type: :request do
  let(:search_path) { '/api/v1/oni/search' }

  before do
    collection = create(:collection, :reindex)
    create(:item, :reindex, collection:)
  end

  # All of these pass Oni::SearchValidator and now resolve to a field mapped in every index, so
  # none of them should raise a query_shard_exception.
  %w[relevance name id title originated_on created_at updated_at].each do |sort|
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
