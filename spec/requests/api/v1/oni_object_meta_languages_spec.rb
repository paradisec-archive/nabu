require 'rails_helper'

# A Language node is identified by its Source's own URI, so the identifier resolves at the registry
# that issued the Code. Nabu holds no verified concordance, so a node never carries another Source's
# code and never claims sameAs; a depositor who wants both rows tags both.
describe 'Oni RO-Crate languages', :no_catalog_upload, type: :request do
  before { sign_in create(:user) }

  let(:iso) { create(:language, code: 'wbp', name: 'Warlpiri', west_limit: nil, south_limit: nil, east_limit: nil, north_limit: nil) }
  let(:glottolog) { create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri') }
  let(:austlang) { create(:language, :austlang, code: 'C15', name: 'Warlpiri') }
  let(:every_source) { [iso, glottolog, austlang] }

  def graph_for(url)
    get "/api/v1/oni/entity/#{CGI.escape(url)}/metadata"

    expect(response).to have_http_status(:ok)
    response.parsed_body['@graph']
  end

  def language_nodes(graph)
    graph.select { |node| node['@type'] == 'Language' }
  end

  def identifier_of(graph, language_node)
    graph.find { |node| node['@id'] == language_node['identifier']['@id'] }
  end

  shared_examples 'a crate identifying languages by Source' do
    it 'identifies a Language from every Source by its Source URI' do
      graph = crate_graph(every_source)

      expect(language_nodes(graph).map { |node| node['@id'] }).to contain_exactly(
        'https://iso639-3.sil.org/code/wbp',
        'https://glottolog.org/resource/languoid/id/warl1254',
        'https://collection.aiatsis.gov.au/austlang/language/C15'
      )
    end

    it 'repeats the Source URI as the node url' do
      graph = crate_graph(every_source)

      expect(language_nodes(graph).map { |node| node['url'] }).to eq(language_nodes(graph).map { |node| node['@id'] })
    end

    it 'keeps the Source name on the node' do
      graph = crate_graph([austlang])

      expect(language_nodes(graph).first['name']).to eq('Warlpiri')
    end

    it 'carries each Source and Code as an identifier PropertyValue' do
      graph = crate_graph(every_source)
      identifiers = language_nodes(graph).map { |node| identifier_of(graph, node) }

      expect(identifiers.map { |node| node.values_at('@type', 'propertyID', 'value') }).to contain_exactly(
        ['PropertyValue', 'iso639-3', 'wbp'],
        ['PropertyValue', 'glottolog', 'warl1254'],
        ['PropertyValue', 'austlang', 'C15']
      )
    end

    it 'drops the bare code from the node' do
      graph = crate_graph(every_source)

      expect(language_nodes(graph).map { |node| node.key?('code') }).to all(be(false))
    end

    it 'asserts no concordance between Sources' do
      graph = crate_graph(every_source)

      expect(language_nodes(graph).map { |node| node.key?('sameAs') }).to all(be(false))
    end

    it 'emits one inLanguage entry per tagged Language' do
      graph = crate_graph([iso, glottolog])
      dataset = graph.find { |node| node['inLanguage'].present? }

      expect(dataset['inLanguage']).to contain_exactly(
        { '@id' => 'https://iso639-3.sil.org/code/wbp' },
        { '@id' => 'https://glottolog.org/resource/languoid/id/warl1254' }
      )
    end

    it 'still gives a Language with a Bounding box its geometry' do
      boxed = create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri',
                                            west_limit: 130.5, south_limit: -22.25, east_limit: 132.5, north_limit: -20.25)
      graph = crate_graph([boxed])

      expect(language_nodes(graph).first['geo']).to be_present
    end
  end

  context 'on an item' do
    # The factory invents a subject language when it is given none, which would add a node of its own.
    def crate_graph(languages)
      item = create(:item, content_languages: languages, subject_languages: languages)
      graph_for(repository_item_url(item.collection, item))
    end

    it_behaves_like 'a crate identifying languages by Source'
  end

  context 'on a collection' do
    def crate_graph(languages)
      graph_for(repository_collection_url(create(:collection, languages:)))
    end

    it_behaves_like 'a crate identifying languages by Source'
  end
end
