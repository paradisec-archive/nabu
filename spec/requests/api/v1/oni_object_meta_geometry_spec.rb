require 'rails_helper'

# Map extents render into RO-Crates as WKT polygons. An extent crossing the
# antimeridian is stored with east < west and a non-positive east edge and must
# unwrap into 0..360 space; a swapped extent (east < west but east positive) is
# bad data and must render as the box the curator meant, never as longitudes
# beyond 360.
describe 'Oni RO-Crate geometry', :no_catalog_upload, type: :request do
  before { sign_in create(:user) }

  def wkt_for(record, url)
    get "/api/v1/oni/entity/#{CGI.escape(url)}/rocrate"

    expect(response).to have_http_status(:ok)
    prefix = "#geo-#{record.west_limit},#{record.south_limit}-"
    geometry = response.parsed_body['@graph'].find { |node| node['@id'].to_s.start_with?(prefix) && node['@type'] == 'Geometry' }

    expect(geometry).to be_present
    geometry['asWKT']
  end

  # Coordinates are stored in single-precision columns, so every value below is
  # binary-exact to keep the rendered strings stable. Extents are written with
  # update_columns because saves now reject the swapped shape.
  def item_wkt(west:, east:)
    item = create(:item, north_limit: -1.5, south_limit: -12.25)
    item.update_columns(west_limit: west, east_limit: east)
    wkt_for(item, repository_item_url(item.collection, item))
  end

  it 'renders an ordinary extent as stored' do
    expect(item_wkt(west: 140.25, east: 154.5))
      .to eq('POLYGON((140.25 -1.5, 154.5 -1.5, 154.5 -12.25, 140.25 -12.25, 140.25 -1.5))')
  end

  it 'unwraps an antimeridian crossing into 0..360 space' do
    expect(item_wkt(west: 170.5, east: -170.25))
      .to eq('POLYGON((170.5 -1.5, 189.75 -1.5, 189.75 -12.25, 170.5 -12.25, 170.5 -1.5))')
  end

  it 'renders a swapped extent as the box the curator meant' do
    expect(item_wkt(west: 154.5, east: 140.25))
      .to eq('POLYGON((140.25 -1.5, 154.5 -1.5, 154.5 -12.25, 140.25 -12.25, 140.25 -1.5))')
  end

  it 'repairs swapped extents in collection crates too' do
    collection = create(:collection, north_limit: -1.5, south_limit: -12.25)
    collection.update_columns(west_limit: 154.5, east_limit: 140.25)

    expect(wkt_for(collection, repository_collection_url(collection)))
      .to eq('POLYGON((140.25 -1.5, 154.5 -1.5, 154.5 -12.25, 140.25 -12.25, 140.25 -1.5))')
  end
end
