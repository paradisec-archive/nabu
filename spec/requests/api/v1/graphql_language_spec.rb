require 'rails_helper'

describe 'GraphQL language', type: :request do
  let(:collection) { create(:collection, private: false) }
  let(:token) { create(:m2m_admin_token) }

  let(:iso) { create(:language, code: 'wbp', name: 'Warlpiri') }
  let(:glottolog) { create(:language, :glottolog_dialect, code: 'lajo1234', name: 'Lajamanu') }
  let(:austlang) { create(:language, :austlang, code: 'C15', name: 'Warlpiri') }
  let(:item) { create(:item, collection:, private: false, content_languages: [iso, glottolog, austlang]) }

  let(:languages_query) do
    <<-GRAPHQL
      query ItemLanguages($fullIdentifier: ID!) {
        item(fullIdentifier: $fullIdentifier) {
          content_languages {
            code
            source
            dialect
            source_uri
            archive_link
            equivalents {
              evidence
              language {
                code
                source
              }
            }
          }
        }
      }
    GRAPHQL
  end

  def execute_graphql(query, variables = {})
    post '/graphql',
         params: { query:, variables: }.to_json,
         headers: { 'Authorization' => "Bearer #{token.token}", 'Content-Type' => 'application/json' }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['errors']).to be_nil

    response.parsed_body['data']
  end

  def content_languages
    data = execute_graphql(languages_query, { fullIdentifier: item.full_identifier })

    data['item']['content_languages'].index_by { |language| language['code'] }
  end

  it 'exposes the source, dialect flag and source URI of a language from each source, with archive_link as its alias' do
    languages = content_languages

    expect(languages['wbp']).to include(
      'source' => 'ISO639_3', 'dialect' => false, 'source_uri' => 'https://iso639-3.sil.org/code/wbp'
    )
    expect(languages['lajo1234']).to include(
      'source' => 'GLOTTOLOG', 'dialect' => true, 'source_uri' => 'https://glottolog.org/resource/languoid/id/lajo1234'
    )
    expect(languages['C15']).to include(
      'source' => 'AUSTLANG', 'dialect' => false, 'source_uri' => 'https://collection.aiatsis.gov.au/austlang/language/C15'
    )
    expect(languages.values).to all(satisfy { |language| language['archive_link'] == language['source_uri'] })
  end

  it 'lists the other language of each equivalent pair with its evidence, from either side of the pair' do
    create(:language_equivalent, language: iso, related_language: austlang, evidence: ['chirila:iso', 'name'])
    create(:language_equivalent, language: glottolog, related_language: austlang, evidence: ['chirila:glottocode'])

    languages = content_languages

    expect(languages['wbp']['equivalents']).to eq([
      { 'evidence' => ['chirila:iso', 'name'], 'language' => { 'code' => 'C15', 'source' => 'AUSTLANG' } }
    ])
    expect(languages['C15']['equivalents']).to contain_exactly(
      { 'evidence' => ['chirila:iso', 'name'], 'language' => { 'code' => 'wbp', 'source' => 'ISO639_3' } },
      { 'evidence' => ['chirila:glottocode'], 'language' => { 'code' => 'lajo1234', 'source' => 'GLOTTOLOG' } }
    )
    expect(languages['lajo1234']['equivalents']).to eq([
      { 'evidence' => ['chirila:glottocode'], 'language' => { 'code' => 'C15', 'source' => 'AUSTLANG' } }
    ])
  end

  it 'marks archive_link as deprecated in the schema' do
    data = execute_graphql(<<-GRAPHQL)
      {
        __type(name: "Language") {
          fields(includeDeprecated: true) {
            name
            isDeprecated
            deprecationReason
          }
        }
      }
    GRAPHQL

    fields = data['__type']['fields'].index_by { |field| field['name'] }

    expect(fields['archive_link']).to include('isDeprecated' => true, 'deprecationReason' => 'Use source_uri')
    expect(fields['source_uri']['isDeprecated']).to be(false)
  end
end
