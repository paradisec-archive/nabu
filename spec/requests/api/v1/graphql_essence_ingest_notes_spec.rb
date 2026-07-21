require 'rails_helper'

# Pins the persistence contract for pipeline notes the paragest ingest service submits
# through the essence create/update mutations.
describe 'GraphQL essence ingest notes', type: :request do
  let(:collection) { create(:collection, private: false) }
  let(:item) { create(:item, collection:, private: false) }
  let(:token) { create(:m2m_admin_token) }
  let(:base_attributes) { { mimetype: 'audio/x-wav', size: 16 } }
  let(:essence) { create(:essence, item:, filename: 'audio.wav', ingest_notes: 'original ingest run', **base_attributes) }

  let(:essence_create_mutation) do
    <<-GRAPHQL
      mutation CreateEssence($collectionIdentifier: String!, $itemIdentifier: String!, $filename: String!, $attributes: EssenceAttributes!) {
        essenceCreate(input: { collectionIdentifier: $collectionIdentifier, itemIdentifier: $itemIdentifier, filename: $filename, attributes: $attributes }) {
          essence {
            filename
          }
        }
      }
    GRAPHQL
  end

  let(:essence_update_mutation) do
    <<-GRAPHQL
      mutation UpdateEssence($id: ID!, $attributes: EssenceAttributes!) {
        essenceUpdate(input: { id: $id, attributes: $attributes }) {
          essence {
            filename
          }
        }
      }
    GRAPHQL
  end

  let(:notes) { "processS3Event: audio.wav added to incoming\nSet volume to -3dB\nCreated MP3 file" }

  def execute_graphql(query, variables)
    post '/graphql',
         params: { query:, variables: }.to_json,
         headers: { 'Authorization' => "Bearer #{token.token}", 'Content-Type' => 'application/json' }

    expect(response).to have_http_status(:ok)

    response.parsed_body
  end

  def create_essence(attributes)
    execute_graphql(essence_create_mutation, {
      collectionIdentifier: collection.identifier,
      itemIdentifier: item.identifier,
      filename: 'audio.wav',
      attributes: base_attributes.merge(attributes)
    })
  end

  def update_essence(essence, attributes)
    execute_graphql(essence_update_mutation, {
      id: essence.id,
      attributes: base_attributes.merge(attributes)
    })
  end

  it 'persists ingest notes supplied on create and records them in version history' do
    result = create_essence(ingestNotes: notes)

    expect(result['errors']).to be_nil

    essence = item.essences.find_by(filename: 'audio.wav')
    expect(essence.ingest_notes).to eq(notes)
    expect(essence.versions.last.changeset['ingest_notes']).to eq([nil, notes])
  end

  it 'leaves ingest notes null when not supplied on create' do
    result = create_essence({})

    expect(result['errors']).to be_nil

    essence = item.essences.find_by(filename: 'audio.wav')
    expect(essence.ingest_notes).to be_nil
  end

  it 'overwrites ingest notes supplied on update' do
    result = update_essence(essence, ingestNotes: notes)

    expect(result['errors']).to be_nil
    expect(essence.reload.ingest_notes).to eq(notes)
  end

  it 'leaves ingest notes untouched when not supplied on update' do
    result = update_essence(essence, {})

    expect(result['errors']).to be_nil
    expect(essence.reload.ingest_notes).to eq('original ingest run')
  end

  it 'records ingest notes changes in version history on update' do
    update_essence(essence, ingestNotes: notes)

    expect(essence.versions.last.changeset['ingest_notes']).to eq(['original ingest run', notes])
  end
end
