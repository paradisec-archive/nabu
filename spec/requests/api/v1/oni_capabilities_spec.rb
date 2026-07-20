require 'rails_helper'

describe 'Oni capabilities', type: :request do
  let(:capabilities_path) { '/api/v1/oni/capabilities' }

  it 'declares the spec version, the segments extension, and typed search filters and facets' do
    get capabilities_path

    expect(response).to have_http_status(:ok)

    body = response.parsed_body
    expect(body['apiVersion']).to eq('0.1.0')
    expect(body['extensions']).to eq('segments' => {})
    expect(body.dig('search', 'filters', 'originatedOn')).to eq('type' => 'date', 'label' => 'Date originated')
    expect(body.dig('search', 'filters', 'languages_with_code')).to eq('type' => 'string', 'label' => 'Language')
    expect(body.dig('search', 'facets', 'languages_with_code')).to eq('label' => 'Language')
  end

  it 'declares every facet as a filter, as the spec requires' do
    get capabilities_path

    search = response.parsed_body['search']
    expect(search['filters'].keys).to include(*search['facets'].keys)
  end
end
