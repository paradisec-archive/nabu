require 'rails_helper'

describe 'Oni capabilities', type: :request do
  let(:capabilities_path) { '/api/v1/oni/capabilities' }

  it 'declares the spec version, the segments extension, and typed search filters and facets' do
    get capabilities_path

    expect(response).to have_http_status(:ok)

    body = response.parsed_body
    expect(body['apiVersion']).to eq('0.4.0')
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

  # Spec 0.4.0 requires both members of every implementation, read-only ones included.
  it 'declares itself read-only, with no deposit fields beyond the supported flag' do
    get capabilities_path

    expect(response.parsed_body['deposit']).to eq('supported' => false)
  end

  it 'declares a single tombstone policy matching the 404 it actually returns' do
    get capabilities_path

    expect(response.parsed_body['tombstonePolicy']).to eq('404')
  end

  it 'does not leak internal filter declaration fields' do
    get capabilities_path

    response.parsed_body.dig('search', 'filters').each_value do |declaration|
      expect(declaration.keys).to all(be_in(%w[type label]))
    end
  end
end
