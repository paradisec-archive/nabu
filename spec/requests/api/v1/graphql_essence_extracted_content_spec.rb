require 'rails_helper'

# The paragest ingest service submits extracted content through the essence create/update
# mutations. This spec pins the persistence contract: content lands in extracted_content with
# extracted_content_type recording which extractor semantics produced it.
describe 'GraphQL essence extracted content', type: :request do
  let(:collection) { create(:collection, private: false) }
  let(:item) { create(:item, collection:, private: false) }
  let(:token) { create(:m2m_admin_token) }

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

  def execute_graphql(query, variables)
    post '/graphql',
         params: { query:, variables: },
         headers: { 'Authorization' => "Bearer #{token.token}" }

    expect(response).to have_http_status(:ok)

    response.parsed_body
  end

  def create_essence(attributes)
    execute_graphql(essence_create_mutation, {
      collectionIdentifier: collection.identifier,
      itemIdentifier: item.identifier,
      filename: 'notes.txt',
      attributes: { mimetype: 'text/plain', size: 16 }.merge(attributes)
    })
  end

  it 'persists extractedText as flat content with type text' do
    result = create_essence(extractedText: 'kurrama word list')

    expect(result['errors']).to be_nil

    essence = item.essences.find_by(filename: 'notes.txt')
    expect(essence.extracted_content).to eq('kurrama word list')
    expect(essence.extracted_content_type).to eq('text')
  end

  it 'leaves both content columns null when no extracted text is supplied' do
    result = create_essence({})

    expect(result['errors']).to be_nil

    essence = item.essences.find_by(filename: 'notes.txt')
    expect(essence.extracted_content).to be_nil
    expect(essence.extracted_content_type).to be_nil
  end
end
