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
         params: { query:, variables: }.to_json,
         headers: { 'Authorization' => "Bearer #{token.token}", 'Content-Type' => 'application/json' }

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

  it 'persists TEXT content as flat content with type text' do
    result = create_essence(extractedContent: { contentType: 'TEXT', text: 'kurrama word list' })

    expect(result['errors']).to be_nil

    essence = item.essences.find_by(filename: 'notes.txt')
    expect(essence.extracted_content).to eq('kurrama word list')
    expect(essence.extracted_content_type).to eq('text')
  end

  it 'persists PDF content as page segments JSON with type pdf' do
    result = create_essence(extractedContent: {
      contentType: 'PDF',
      segments: [
        { type: 'PAGE', text: 'kurrama word list', page: 1 },
        { type: 'PAGE', text: 'field notes continued', page: 2 }
      ]
    })

    expect(result['errors']).to be_nil

    essence = item.essences.find_by(filename: 'notes.txt')
    expect(essence.extracted_content_type).to eq('pdf')
    expect(JSON.parse(essence.extracted_content)).to eq([
      { 'type' => 'page', 'text' => 'kurrama word list', 'page' => 1 },
      { 'type' => 'page', 'text' => 'field notes continued', 'page' => 2 }
    ])
  end

  it 'leaves both content columns null when no extracted text is supplied' do
    result = create_essence({})

    expect(result['errors']).to be_nil

    essence = item.essences.find_by(filename: 'notes.txt')
    expect(essence.extracted_content).to be_nil
    expect(essence.extracted_content_type).to be_nil
  end

  it 'accepts extractedContent on essence update' do
    essence = create(:essence, item:, filename: 'notes.pdf', mimetype: 'application/pdf', size: 16)

    mutation = <<-GRAPHQL
      mutation UpdateEssence($id: ID!, $attributes: EssenceAttributes!) {
        essenceUpdate(input: { id: $id, attributes: $attributes }) {
          essence {
            filename
          }
        }
      }
    GRAPHQL

    result = execute_graphql(mutation, {
      id: essence.id,
      attributes: {
        mimetype: 'application/pdf',
        size: 16,
        extractedContent: { contentType: 'PDF', segments: [{ type: 'PAGE', text: 'kurrama word list', page: 3 }] }
      }
    })

    expect(result['errors']).to be_nil

    essence.reload
    expect(essence.extracted_content_type).to eq('pdf')
    expect(JSON.parse(essence.extracted_content)).to eq([{ 'type' => 'page', 'text' => 'kurrama word list', 'page' => 3 }])
  end

  it 'rejects the removed extractedText argument' do
    result = create_essence(extractedText: 'kurrama word list')

    expect(result['errors'].to_s).to include('extractedText')
    expect(item.essences.find_by(filename: 'notes.txt')).to be_nil
  end

  # GraphQL cannot express conditional requiredness, so the invalid combinations must surface
  # as schema-boundary errors and persist nothing.
  {
    'TEXT without text' => { contentType: 'TEXT' },
    'TEXT with segments' => { contentType: 'TEXT', text: 'x', segments: [{ type: 'PAGE', text: 'x', page: 1 }] },
    'PDF without segments' => { contentType: 'PDF' },
    'PDF with text' => { contentType: 'PDF', text: 'x', segments: [{ type: 'PAGE', text: 'x', page: 1 }] },
    'a PAGE segment missing page' => { contentType: 'PDF', segments: [{ type: 'PAGE', text: 'x' }] },
    'a segment with blank text' => { contentType: 'PDF', segments: [{ type: 'PAGE', text: '   ', page: 1 }] }
  }.each do |label, extracted_content|
    it "rejects #{label} with a schema-boundary error" do
      result = create_essence(extractedContent: extracted_content)

      expect(result['errors'].to_s).to include('extractedContent')
      expect(item.essences.find_by(filename: 'notes.txt')).to be_nil
    end
  end
end
