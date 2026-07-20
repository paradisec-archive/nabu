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

  it 'matches inside PDF page segments and returns page locations with highlights' do
    create(:essence, :reindex, item:, filename: 'fieldnotes.pdf', mimetype: 'application/pdf', size: 16,
                               extracted_content: [
                                 { type: 'page', text: 'An unrelated introduction', page: 1 },
                                 { type: 'page', text: 'The kurrama word list', page: 4 }
                               ].to_json,
                               extracted_content_type: 'pdf')

    post search_path, params: { query: 'kurrama' }

    expect(response).to have_http_status(:ok)

    entity = find_entity('fieldnotes.pdf')
    expect(entity).to be_present

    segments = entity.dig('searchExtra', 'segments')
    expect(segments.length).to eq(1)
    expect(segments.first['type']).to eq('page')
    expect(segments.first['page']).to eq(4)
    expect(segments.first['highlight'].join).to include('<mark class="font-bold">kurrama</mark>')
  end

  it 'caps segment locations at 5 per file' do
    pages = (1..7).map { |page| { type: 'page', text: "kurrama vocabulary page #{page}", page: } }
    create(:essence, :reindex, item:, filename: 'fieldnotes.pdf', mimetype: 'application/pdf', size: 16,
                               extracted_content: pages.to_json, extracted_content_type: 'pdf')

    post search_path, params: { query: 'kurrama' }

    segments = find_entity('fieldnotes.pdf').dig('searchExtra', 'segments')
    expect(segments.length).to eq(5)
  end

  it 'matches page segments in advanced search mode' do
    create(:essence, :reindex, item:, filename: 'fieldnotes.pdf', mimetype: 'application/pdf', size: 16,
                               extracted_content: [{ type: 'page', text: 'The kurrama word list', page: 4 }].to_json,
                               extracted_content_type: 'pdf')

    post search_path, params: { searchType: 'advanced', query: 'kurrama' }

    expect(response).to have_http_status(:ok)

    segments = find_entity('fieldnotes.pdf').dig('searchExtra', 'segments')
    expect(segments.first['page']).to eq(4)
    expect(segments.first['highlight'].join).to include('<mark class="font-bold">kurrama</mark>')
  end

  it 'keeps private essences invisible to unauthenticated users even when segments match' do
    private_item = create(:item, collection:, private: true)
    create(:essence, :reindex, item: private_item, filename: 'secret.pdf', mimetype: 'application/pdf', size: 16,
                               extracted_content: [{ type: 'page', text: 'The kurrama word list', page: 1 }].to_json,
                               extracted_content_type: 'pdf')

    post search_path, params: { query: 'kurrama' }

    expect(response).to have_http_status(:ok)
    expect(find_entity('secret.pdf')).to be_nil
  end

  it 'matches inside ELAN annotation segments and returns tier and timecodes with highlights' do
    create(:essence, :reindex, item:, filename: 'transcript.eaf', mimetype: 'text/xml', size: 16,
                               extracted_content: [
                                 { type: 'time-aligned-annotation', text: 'ngayu kurrama', tier: 'tx@EDD', start_ms: 192_000, end_ms: 195_400 },
                                 { type: 'time-aligned-annotation', text: 'something else', tier: 'ft@EDD', start_ms: 192_000, end_ms: 195_400 }
                               ].to_json,
                               extracted_content_type: 'elan')

    post search_path, params: { query: 'kurrama' }

    expect(response).to have_http_status(:ok)

    segments = find_entity('transcript.eaf').dig('searchExtra', 'segments')
    expect(segments.length).to eq(1)
    expect(segments.first).to include(
      'type' => 'time-aligned-annotation',
      'tier' => 'tx@EDD',
      'startMs' => 192_000,
      'endMs' => 195_400
    )
    expect(segments.first['highlight'].join).to include('<mark class="font-bold">kurrama</mark>')
  end

  it 'returns correct per-type searchExtra shapes across a mixed corpus in one result set' do
    create(:essence, :reindex, item:, filename: 'fieldnotes.pdf', mimetype: 'application/pdf', size: 16,
                               extracted_content: [{ type: 'page', text: 'The kurrama word list', page: 4 }].to_json,
                               extracted_content_type: 'pdf')
    create(:essence, :reindex, item:, filename: 'transcript.eaf', mimetype: 'text/xml', size: 16,
                               extracted_content: [{ type: 'time-aligned-annotation', text: 'ngayu kurrama', tier: 'tx@EDD', start_ms: 0, end_ms: 1500 }].to_json,
                               extracted_content_type: 'elan')
    create(:essence, :reindex, item:, filename: 'notes.txt', mimetype: 'text/plain', size: 16,
                               extracted_content: 'The kurrama word list from the field trip', extracted_content_type: 'text')

    post search_path, params: { query: 'kurrama' }

    expect(response).to have_http_status(:ok)

    pdf_segments = find_entity('fieldnotes.pdf').dig('searchExtra', 'segments')
    expect(pdf_segments).to eq([{ 'type' => 'page', 'page' => 4, 'highlight' => ['The <mark class="font-bold">kurrama</mark> word list'] }])

    elan_segments = find_entity('transcript.eaf').dig('searchExtra', 'segments')
    expect(elan_segments).to eq([{ 'type' => 'time-aligned-annotation', 'tier' => 'tx@EDD', 'startMs' => 0, 'endMs' => 1500,
                                   'highlight' => ['ngayu <mark class="font-bold">kurrama</mark>'] }])

    flat = find_entity('notes.txt')
    expect(flat.dig('searchExtra', 'segments')).to be_nil
    expect(flat.dig('searchExtra', 'highlight', 'extracted_text').join).to include('<mark class="font-bold">kurrama</mark>')
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
