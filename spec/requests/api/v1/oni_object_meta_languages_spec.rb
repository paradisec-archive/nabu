require 'rails_helper'

# A Language node is identified by its Source's own URI, so the identifier resolves at the registry
# that issued the Code. Nabu holds no verified concordance, so a node never carries another Source's
# code and never claims sameAs; a depositor who wants both rows tags both.
describe 'Oni RO-Crate languages', :no_catalog_upload, type: :request do
  before { sign_in create(:user) }

  let(:iso) { create(:language, code: 'wbp', name: 'Warlpiri', west_limit: nil, south_limit: nil, east_limit: nil, north_limit: nil) }
  let(:glottolog) { create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri') }
  let(:austlang) { create(:language, :austlang, code: 'C15', name: 'Warlpiri') }

  def graph_for(url)
    get "/api/v1/oni/entity/#{CGI.escape(url)}/metadata"

    expect(response).to have_http_status(:ok)
    response.parsed_body['@graph']
  end

  def language_nodes(graph)
    graph.select { |node| node['@type'] == 'Language' }
  end

  # The factory invents a subject language when it is given none, which would add a node of its own.
  def item_graph(content_languages:, subject_languages: content_languages)
    item = create(:item, content_languages:, subject_languages:)
    graph_for(repository_item_url(item.collection, item))
  end

  it 'identifies a Language from every Source by its Source URI' do
    graph = item_graph(content_languages: [iso, glottolog, austlang])

    expect(language_nodes(graph).map { |node| node['@id'] }).to contain_exactly(
      'https://iso639-3.sil.org/code/wbp',
      'https://glottolog.org/resource/languoid/id/warl1254',
      'https://collection.aiatsis.gov.au/austlang/language/C15'
    )
  end

  it 'repeats the Source URI as the node url' do
    graph = item_graph(content_languages: [glottolog])
    node = language_nodes(graph).first

    expect(node['url']).to eq('https://glottolog.org/resource/languoid/id/warl1254')
  end

  it 'keeps the Source name on the node' do
    graph = item_graph(content_languages: [austlang])

    expect(language_nodes(graph).first['name']).to eq('Warlpiri')
  end

  it 'carries the Source and the Code as an identifier PropertyValue' do
    graph = item_graph(content_languages: [glottolog])
    identifier = language_nodes(graph).first['identifier']
    property_value = graph.find { |node| node['@id'] == identifier['@id'] }

    expect(property_value).to include('@type' => 'PropertyValue', 'propertyID' => 'glottolog', 'value' => 'warl1254')
  end

  it 'names the ISO 639-3 Source as iso639-3 in the identifier' do
    graph = item_graph(content_languages: [iso])
    identifier = language_nodes(graph).first['identifier']

    expect(graph.find { |node| node['@id'] == identifier['@id'] }).to include('propertyID' => 'iso639-3', 'value' => 'wbp')
  end

  it 'drops the bare code from the node' do
    graph = item_graph(content_languages: [iso, glottolog, austlang])

    expect(language_nodes(graph).map { |node| node.key?('code') }).to all(be(false))
  end

  it 'asserts no concordance between Sources' do
    graph = item_graph(content_languages: [iso, glottolog, austlang])

    expect(language_nodes(graph).map { |node| node.key?('sameAs') }).to all(be(false))
  end

  it 'emits one inLanguage entry per tagged Language' do
    item = create(:item, content_languages: [iso, glottolog])
    graph = graph_for(repository_item_url(item.collection, item))
    dataset = graph.find { |node| node['inLanguage'].present? }

    expect(dataset['inLanguage']).to contain_exactly(
      { '@id' => 'https://iso639-3.sil.org/code/wbp' },
      { '@id' => 'https://glottolog.org/resource/languoid/id/warl1254' }
    )
  end

  it 'still gives a Language with a Bounding box its geometry' do
    boxed = create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri',
                                          west_limit: 130.5, south_limit: -22.25, east_limit: 132.5, north_limit: -20.25)
    graph = item_graph(content_languages: [boxed])

    expect(language_nodes(graph).first['geo']).to be_present
  end

  it 'identifies a Language the same way in a collection crate' do
    collection = create(:collection, languages: [austlang])
    graph = graph_for(repository_collection_url(collection))
    node = language_nodes(graph).find { |candidate| candidate['@id'].include?('austlang') }

    expect(node).to include('@id' => 'https://collection.aiatsis.gov.au/austlang/language/C15',
                            'url' => 'https://collection.aiatsis.gov.au/austlang/language/C15')
    expect(node).not_to have_key('code')
  end
end
