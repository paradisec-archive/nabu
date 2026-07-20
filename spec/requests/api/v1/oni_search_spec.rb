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

  it 'still returns 400 for an entirely invalid sort field (validator rejects it)' do
    post search_path, params: { query: '*', sort: 'not_a_field' }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig('error', 'code')).to eq('VALIDATION_ERROR')
  end

  # Per the RO-Crate search spec, `filters` is an object mapping field names to arrays of strings.
  # A client sending `filters` as a top-level array used to reach filters.key?(...) in the validator
  # and raise NoMethodError -> HTTP 500. It must be rejected as invalid input instead (NABU-N9).
  it 'returns 400 (not a 500) when filters is an array rather than an object' do
    post search_path, params: { query: '*', filters: ['2020-01-01T00:00:00.000Z TO 2021-01-01T00:00:00.000Z'] }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig('error', 'message')).to include('Filters must be an object')
  end

  # A valid filters object arrives as ActionController::Parameters (not a plain Hash), so the
  # validator must accept it rather than rejecting it as "must be an object" (NABU-N9).
  it 'returns 200 when passing a valid filter object' do
    post search_path, params: { searchType: 'basic', query: '', limit: 50, offset: 0, filters: { collection_title: ['Moo'] } }

    expect(response).to have_http_status(:ok)
  end
end
