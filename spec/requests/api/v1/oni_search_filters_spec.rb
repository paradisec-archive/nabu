require 'rails_helper'

# The RO-Crate API spec ties search filters to the GET /capabilities declaration: undeclared
# filter keys MUST be rejected with a 400 ValidationError, date/number filters accept an
# inclusive gte/lte range object or a non-empty array of them matched as an OR, an array MUST
# NOT mix exact terms and range objects, and a range sent to a string filter MUST be rejected.
describe 'Oni search filters', :no_catalog_upload, :search, type: :request do
  let(:search_path) { '/api/v1/oni/search' }
  let(:collection) { create(:collection, :reindex) }

  before do
    create(:item, :reindex, collection:, identifier: 'OLD', originated_on: Date.new(1965, 3, 1))
    create(:item, :reindex, collection:, identifier: 'MID', originated_on: Date.new(1980, 6, 1))
    create(:item, :reindex, collection:, identifier: 'NEW', originated_on: Date.new(1999, 8, 1))
  end

  def item_identifiers
    response.parsed_body['entities'].filter_map { |entity| entity.dig('identifiers', 'itemIdentifier') }
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

  it 'rejects an array of range objects sent to a string filter' do
    post search_path, params: { query: '*', filters: { collection_title: [{ gte: 'a', lte: 'b' }] } }

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
    expect(item_identifiers).to include('OLD')
    expect(item_identifiers).not_to include('NEW')
  end

  # Spec 0.2.0: a date/number filter value may be a non-empty array of range objects, matched as
  # an OR of the ranges. Oni's date facet sends this shape even for a single selected year.
  it 'accepts a single-element array of range objects' do
    post search_path, params: { query: '*', filters: { originatedOn: [{ gte: '1965-01-01', lte: '1965-12-31' }] } }

    expect(response).to have_http_status(:ok)
    expect(item_identifiers).to contain_exactly('OLD')
  end

  it 'ORs a multi-element array of range objects' do
    post search_path, params: {
      query: '*',
      filters: { originatedOn: [{ gte: '1965-01-01', lte: '1965-12-31' }, { gte: '1999-01-01', lte: '1999-12-31' }] }
    }

    expect(response).to have_http_status(:ok)
    expect(item_identifiers).to contain_exactly('OLD', 'NEW')
  end

  it 'accepts a range array with only one bound' do
    post search_path, params: { query: '*', filters: { originatedOn: [{ gte: '1990-01-01' }] } }

    expect(response).to have_http_status(:ok)
    expect(item_identifiers).to contain_exactly('NEW')
  end

  it 'rejects an array mixing exact terms and range objects' do
    post search_path, params: { query: '*', filters: { originatedOn: ['1965-03-01', { gte: '1999-01-01' }] } }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig('error', 'code')).to eq('VALIDATION_ERROR')
    expect(response.parsed_body.dig('error', 'message')).to include('originatedOn')
  end

  it 'rejects a range object inside an array whose bounds are not ISO 8601 dates' do
    post search_path, params: { query: '*', filters: { originatedOn: [{ gte: 'last tuesday' }] } }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig('error', 'code')).to eq('VALIDATION_ERROR')
  end

  # The bound is passed to OpenSearch exactly as the client sent it. OpenSearch rounds a
  # date-only lte up to the last millisecond of that day, so the last day of a selected year
  # is included. Expanding the bound to an explicit timestamp here would silently drop it.
  it 'includes an entity stamped on the last day of a whole-year range' do
    create(:item, :reindex, collection:, identifier: 'EVE', originated_on: Date.new(1965, 12, 31))

    post search_path, params: { query: '*', filters: { originatedOn: [{ gte: '1965-01-01', lte: '1965-12-31' }] } }

    expect(response).to have_http_status(:ok)
    expect(item_identifiers).to include('EVE')
  end

  it 'treats an array of plain strings on a date filter as exact terms' do
    post search_path, params: { query: '*', filters: { originatedOn: ['1980-06-01'] } }

    expect(response).to have_http_status(:ok)
    expect(item_identifiers).to contain_exactly('MID')
  end

  # The legacy Oni 'A TO B' range string is no longer accepted. Old bookmarks get a clear 400
  # rather than an OpenSearch date-parse failure.
  it 'rejects the legacy "A TO B" originatedOn range string' do
    post search_path, params: { query: '*', filters: { originatedOn: ['1960-01-01T00:00:00.000Z TO 1970-01-01T00:00:00.000Z'] } }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig('error', 'code')).to eq('VALIDATION_ERROR')
  end
end
