require 'rails_helper'

# The entity_type facet speaks the API's names for the internal models: an Essence is a File.
# The spec requires every facet value to also work as a filter, so a bucket name must round-trip.
describe 'Oni search entity_type facet', :no_catalog_upload, :search, type: :request do
  let(:search_path) { '/api/v1/oni/search' }

  let(:collection) { create(:collection, :reindex, private: false) }
  let(:item) { create(:item, :reindex, collection:, private: false) }

  before do
    create(:essence, :reindex, item:, filename: 'moo.wav', mimetype: 'audio/wav', size: 16)
  end

  def facet_names
    response.parsed_body.dig('facets', 'entity_type').map { |bucket| bucket['name'] }
  end

  it 'returns File rather than Essence in the entity_type buckets' do
    post search_path, params: { query: '*' }

    expect(response).to have_http_status(:ok)
    expect(facet_names).to contain_exactly('Collection', 'Item', 'File')
  end

  it 'filters on the File bucket name' do
    post search_path, params: { query: '*', filters: { entity_type: ['File'] } }

    expect(response).to have_http_status(:ok)
    expect(facet_names).to contain_exactly('File')
    expect(response.parsed_body['entities'].map { |entity| entity.dig('identifiers', 'filename') }).to contain_exactly('moo.wav')
  end

  it 'still filters on the internal name and the PCDM URI' do
    post search_path, params: { query: '*', filters: { entity_type: ['Essence'] } }
    expect(facet_names).to contain_exactly('File')

    post search_path, params: { query: '*', filters: { entity_type: ['http://schema.org/MediaObject'] } }
    expect(facet_names).to contain_exactly('File')
  end

  it 'rejects an unknown entity_type with a 400' do
    post search_path, params: { query: '*', filters: { entity_type: ['Widget'] } }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig('error', 'message')).to include('Widget')
  end
end
