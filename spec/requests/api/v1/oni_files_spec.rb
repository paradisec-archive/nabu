require 'rails_helper'

# The Oni /files endpoint lists Essence entities. For each essence the view walks essence.item and
# essence.collection (delegated to item.collection) and calls can?(:read, essence), which checks the
# item's access_condition plus item/collection permission grants. Those associations must be
# eager-loaded or the endpoint fires a per-essence item/collection load (NABU-MZ) plus a latent
# permission-check N+1.
describe 'Oni files listing', :no_catalog_upload, type: :request do
  let(:files_path) { '/api/v1/oni/files' }

  # Distinct collection/item per essence so a genuine N+1 would scale the item/collection query
  # count with the number of rows; eager loading keeps it to a single IN(...) load each.
  def create_essences(count)
    Array.new(count) do
      collection = create(:collection)
      item = create(:item, collection:)
      create(:essence, item:, size: 1_234)
    end
  end

  it 'returns each essence with its item and collection context' do
    essence = create_essences(1).first

    get files_path

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body['total']).to eq(1)
    file = body['files'].first
    expect(file['filename']).to eq(essence.filename)
    expect(file['memberOf']['name']).to eq(essence.item.title)
    expect(file['rootCollection']['name']).to eq(essence.collection.title)
  end

  it 'does not fire a per-essence item/collection N+1' do
    create_essences(3)

    item_queries = 0
    collection_queries = 0
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      sql = payload[:sql]
      item_queries += 1 if sql.match?(/FROM ["`]items["`]/)
      collection_queries += 1 if sql.match?(/FROM ["`]collections["`]/)
    end

    get files_path

    ActiveSupport::Notifications.unsubscribe(subscriber)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['total']).to eq(3)
    # Eager loading resolves all three items and collections in one batched query each; a regression
    # to per-row loading would push these to ~3 and fail here.
    expect(item_queries).to be <= 1
    expect(collection_queries).to be <= 1
  end
end
