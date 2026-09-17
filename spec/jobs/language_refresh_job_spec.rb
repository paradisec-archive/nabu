require 'rails_helper'

describe LanguageRefreshJob do
  let(:fixtures) { Rails.root.join('spec/support/data/language_refresh') }

  before do
    stub_request(:get, LanguageRefresh::IsoStage::SIL_CODES_URL).to_return(body: fixtures.join('iso-639-3.tab').read)
    stub_request(:get, LanguageRefresh::IsoStage::SIL_RETIREMENTS_URL).to_return(body: fixtures.join('iso-639-3_Retirements.tab').read)
    stub_request(:get, LanguageRefresh::IsoStage::ETHNOLOGUE_INDEX_URL).to_return(body: fixtures.join('LanguageIndex.tab').read)
    stub_request(:get, LanguageRefresh::GlottologStage::RELEASES_URL).to_return(body: { tag_name: 'v5.3' }.to_json)
    stub_request(:get, format(LanguageRefresh::GlottologStage::LANGUAGES_URL, 'v5.3'))
      .to_return(body: fixtures.join('glottolog-languages.csv').read)
  end

  it 'runs the Refresh over every Source' do
    described_class.perform_now

    expect(LanguageRefreshRun.sole).to be_completed
    expect(Language.iso639_3.count).to eq(34)
    expect(Language.glottolog.count).to eq(5)
  end

  it 'runs on the maintenance queue' do
    expect(described_class.new.queue_name).to eq('maintenance')
  end
end
