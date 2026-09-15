require 'rails_helper'

describe LanguageRefreshJob, :webmock do
  let(:fixtures) { Rails.root.join('spec/support/data/language_refresh') }

  before do
    stub_request(:get, LanguageRefresh::IsoStage::SIL_CODES_URL).to_return(body: fixtures.join('iso-639-3.tab').read)
    stub_request(:get, LanguageRefresh::IsoStage::ETHNOLOGUE_INDEX_URL).to_return(body: fixtures.join('LanguageIndex.tab').read)
  end

  it 'runs the Refresh' do
    described_class.perform_now

    expect(LanguageRefreshRun.sole).to be_completed
    expect(Language.iso639_3.count).to eq(34)
  end

  it 'runs on the maintenance queue' do
    expect(described_class.new.queue_name).to eq('maintenance')
  end
end
