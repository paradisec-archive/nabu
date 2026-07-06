require 'rails_helper'

# Full-text search over extracted content through the public Oni search endpoint. Flat-text rows
# must keep matching and highlighting exactly as they did before the structured-content work.
describe 'Oni search over extracted content', :no_catalog_upload, :search, type: :request do
  let(:search_path) { '/api/v1/oni/search' }

  let(:collection) { create(:collection, private: false) }
  let(:item) { create(:item, collection:, private: false) }

  def find_entity(filename)
    response.parsed_body['entities'].find { |e| e.dig('identifiers', 'filename') == filename }
  end

  it 'matches flat extracted text and highlights it' do
    create(:essence, :reindex, item:, filename: 'notes.txt', mimetype: 'text/plain', size: 16,
                               extracted_content: 'The kurrama word list from the field trip', extracted_content_type: 'text')

    post search_path, params: { query: 'kurrama' }

    expect(response).to have_http_status(:ok)

    entity = find_entity('notes.txt')
    expect(entity).to be_present
    highlight = entity.dig('searchExtra', 'highlight', 'extracted_text')
    expect(highlight.join).to include('<mark class="font-bold">kurrama</mark>')
  end
end
