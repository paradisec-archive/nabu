require 'rails_helper'

# The RO-Crate API spec ties search filters to the GET /capabilities declaration: undeclared
# filter keys MUST be rejected with a 400 ValidationError, date/number filters accept an
# inclusive gte/lte range object, and a range sent to a string filter MUST be rejected.
describe 'Oni search filters', :no_catalog_upload, :search, type: :request do
  let(:search_path) { '/api/v1/oni/search' }
  let(:collection) { create(:collection, :reindex) }

  before do
    create(:item, :reindex, collection:, identifier: 'OLD', originated_on: Date.new(1965, 3, 1))
    create(:item, :reindex, collection:, identifier: 'NEW', originated_on: Date.new(1999, 8, 1))
  end

  it 'rejects a filter key not declared in /capabilities with a 400 ValidationError' do
    post search_path, params: { query: '*', filters: { not_a_filter: ['x'] } }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig('error', 'code')).to eq('VALIDATION_ERROR')
    expect(response.parsed_body.dig('error', 'message')).to include('not_a_filter')
  end

  it 'rejects a range object sent to a string filter' do
    post search_path, params: { query: '*', filters: { collection_title: { gte: 'a' } } }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig('error', 'message')).to include('collection_title')
  end

  it 'rejects a range object with unknown keys or no bounds' do
    post search_path, params: { query: '*', filters: { originatedOn: { above: '1960-01-01' } } }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig('error', 'code')).to eq('VALIDATION_ERROR')
  end

  it 'filters by the spec gte/lte range object on a date filter' do
    post search_path, params: { query: '*', filters: { originatedOn: { gte: '1960-01-01', lte: '1970-01-01' } } }

    expect(response).to have_http_status(:ok)
    identifiers = response.parsed_body['entities'].filter_map { |entity| entity.dig('identifiers', 'itemIdentifier') }
    expect(identifiers).to include('OLD')
    expect(identifiers).not_to include('NEW')
  end

  it 'still accepts the legacy "A TO B" originatedOn range strings Oni sends' do
    post search_path, params: { query: '*', filters: { originatedOn: ['1960-01-01T00:00:00.000Z TO 1970-01-01T00:00:00.000Z'] } }

    expect(response).to have_http_status(:ok)
    identifiers = response.parsed_body['entities'].filter_map { |entity| entity.dig('identifiers', 'itemIdentifier') }
    expect(identifiers).to include('OLD')
    expect(identifiers).not_to include('NEW')
  end
end
