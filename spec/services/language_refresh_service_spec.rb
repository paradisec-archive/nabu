require 'rails_helper'
require 'sentry/test_helper'

describe LanguageRefreshService do
  let(:fixtures) { Rails.root.join('spec/support/data/language_refresh') }
  let(:sil_codes_url) { LanguageRefresh::IsoStage::SIL_CODES_URL }
  let(:sil_retirements_url) { LanguageRefresh::IsoStage::SIL_RETIREMENTS_URL }
  let(:ethnologue_index_url) { LanguageRefresh::IsoStage::ETHNOLOGUE_INDEX_URL }
  let(:sil_codes) { fixtures.join('iso-639-3.tab').read }
  let(:refresh) { described_class.new(fetcher: LanguageRefresh::Fetcher.new(backoff: 0)) }

  let!(:australia) { create(:country, code: 'AU', name: 'Australia') }
  let!(:papua_new_guinea) { create(:country, code: 'PG', name: 'Papua New Guinea') }
  let!(:vanuatu) { create(:country, code: 'VU', name: 'Vanuatu') }

  def body_of(mail)
    (mail.text_part || mail.body).decoded
  end

  before do
    stub_request(:get, sil_codes_url).to_return(body: sil_codes, headers: { 'Last-Modified' => 'Wed, 22 Jul 2026 17:03:19 GMT' })
    stub_request(:get, sil_retirements_url)
      .to_return(body: fixtures.join('iso-639-3_Retirements.tab').read, headers: { 'Last-Modified' => 'Mon, 13 Jul 2026 04:12:00 GMT' })
    stub_request(:get, ethnologue_index_url)
      .to_return(body: fixtures.join('LanguageIndex.tab').read, headers: { 'Last-Modified' => 'Fri, 27 Feb 2026 21:59:51 GMT' })
    ActionMailer::Base.deliveries.clear
  end

  describe 'a first Run against an ISO-only database' do
    let!(:warlpiri) { create(:language, code: 'wbp', name: 'Warlpiri') }
    let!(:tok_pisin) { create(:language, code: 'tpi', name: 'Pisin, Tok') }

    it 'creates every ISO 639-3 code it does not hold and renames the ones whose name changed' do
      refresh.run

      expect(Language.iso639_3.count).to eq(34)
      expect(Language.find_by(code: 'akk', source: :iso639_3).name).to eq('Akkadian')
      expect(Language.find_by(code: 'zxx', source: :iso639_3).name).to eq('No linguistic content')
      expect(tok_pisin.reload.name).to eq('Tok Pisin')
      expect(warlpiri.reload.name).to eq('Warlpiri')
    end

    it 'adds the country links Ethnologue lists and keeps the ones it does not' do
      warlpiri.countries << papua_new_guinea

      refresh.run

      expect(warlpiri.reload.countries).to contain_exactly(australia, papua_new_guinea)
      expect(Language.find_by(code: 'bis').countries).to contain_exactly(vanuatu)
      expect(Language.find_by(code: 'pjt').countries).to contain_exactly(australia)
    end

    it 'writes no PaperTrail versions for the languages it creates or renames' do
      expect { refresh.run }.not_to(change { PaperTrail::Version.where(item_type: %w[Language CountriesLanguage]).count })
    end

    it 'records the Run with the versions it read and what it changed' do
      refresh.run

      run = LanguageRefreshRun.sole
      expect(run).to have_attributes(status: 'completed', started_at: be_present, finished_at: be_present)
      expect(run.sources['iso639_3']).to include(
        'status' => 'applied',
        'version' => {
          'iso-639-3.tab' => '2026-07-22', 'iso-639-3_Retirements.tab' => '2026-07-13', 'LanguageIndex.tab' => '2026-02-27'
        },
        'rows' => 34,
        'counts' => { 'country_links_added' => 5 }
      )
      expect(run.sources.dig('iso639_3', 'changes', 'new').size).to eq(32)
      expect(run.sources.dig('iso639_3', 'changes', 'renamed')).to eq([['tpi', 'Pisin, Tok', 'Tok Pisin']])
    end

    it 'emails one report with the counts in the subject, a section per Source and a long list attached as CSV' do
      refresh.run

      mail = ActionMailer::Base.deliveries.sole
      expect(mail.to).to eq(['johnf@inodes.org'])
      expect(mail.subject).to eq(
        '[NABU Admin] Language Refresh: 0 need a person, 0 failures, 32 new, 1 renamed, 0 retired, 0 reinstated'
      )

      body = body_of(mail)
      expect(body).to include(
        "ISO 639-3\nStatus: applied\nVersions: iso-639-3.tab 2026-07-22, iso-639-3_Retirements.tab 2026-07-13, LanguageIndex.tab 2026-02-27"
      )
      expect(body).to include("Renamed: 1\n  Tok Pisin (tpi) · ISO 639-3, was Pisin, Tok")
      expect(body).to include("New: 32\n  Ghotuo (aaa) · ISO 639-3\n")
      expect(body).to include('and 12 more in iso639_3-new.csv')
      expect(body).to include("Country links added: 5\n")
      expect(body).to include("Needs a person\nNothing needs a person.")

      rows = CSV.parse(mail.attachments['iso639_3-new.csv'].decoded, headers: true)
      expect(rows.size).to eq(32)
      expect(rows.first.to_h).to eq('code' => 'aaa', 'name' => 'Ghotuo')
      expect(mail.attachments['iso639_3-renamed.csv']).to be_nil

      expect(LanguageRefreshRun.sole.report).to eq(body.chomp)
    end
  end

  describe 'ISO 639-3 retirements' do
    let!(:aariya) { create(:language, code: 'aaj', name: 'Aariya') }
    let!(:afar) { create(:language, code: 'aar', name: 'Afar') }

    def held_section(body)
      body[/^Needs a person\n.*?\n\nFailures$/m].to_s
    end

    it 'retires a one-to-one retirement and moves every tag to the replacement without duplicating one' do
      collection = create(:collection, languages: [aariya])
      item = create(:item, collection:, content_languages: [aariya], subject_languages: [aariya])
      already_tagged = create(:item, collection:, content_languages: [aariya, afar], subject_languages: [afar])
      aariya.countries << australia

      refresh.run

      expect(aariya.reload).to have_attributes(retired: true, name: 'Aariya')
      expect(collection.reload.languages).to contain_exactly(afar)
      expect(item.reload.content_languages).to contain_exactly(afar)
      expect(item.subject_languages).to contain_exactly(afar)
      expect(already_tagged.reload.content_languages).to contain_exactly(afar)
      expect(afar.reload.countries).to contain_exactly(australia)
      expect(Language.tagged).not_to include(aariya)
    end

    it 'reindexes the replacement so the tags it took on do not read the retired Label', :no_catalog_upload do
      collection = create(:collection, languages: [aariya])
      create(:item, collection:, content_languages: [aariya], subject_languages: [aariya])

      expect { refresh.run }.to have_enqueued_job(LanguageReindexJob).with(afar).exactly(:once)
    end

    it 'leaves PaperTrail versions on the rewritten join rows naming the Run, and none on the Language' do
      create(:collection, languages: [aariya])
      PaperTrail::Version.delete_all

      refresh.run

      expect(PaperTrail::Version.where(item_type: 'CollectionLanguage').pluck(:whodunnit).uniq)
        .to eq(["Language Refresh Run #{LanguageRefreshRun.sole.id}"])
      expect(PaperTrail::Version.where(item_type: 'Language')).to be_empty
    end

    it 'retires a split retirement, rewrites nothing, and lists it under needs a person every Run' do
      mandobo = create(:language, code: 'aax', name: 'Mandobo Atas')
      collection = create(:collection, languages: [mandobo])
      item = create(:item, collection:, content_languages: [mandobo], subject_languages: [afar])

      refresh.run

      expect(mandobo.reload.retired).to be(true)
      expect(collection.reload.languages).to include(mandobo)
      expect(item.reload.content_languages).to contain_exactly(mandobo)

      expect(held_section(body_of(ActionMailer::Base.deliveries.sole))).to eq(<<~SECTION.chomp)
        Needs a person
        Mandobo Atas (aax) · ISO 639-3
          Retired: split
          Remedy: Split into Ambrak [aag] and Amal [aad]
          Tagged: collection_languages 1, item_content_languages 1
          #{collection.identifier}: https://www.example.com/collections/#{collection.identifier}/edit
          #{item.full_identifier}: https://www.example.com/collections/#{collection.identifier}/items/#{item.identifier}/edit

        Failures
      SECTION

      refresh.run

      expect(held_section(body_of(ActionMailer::Base.deliveries.last))).to include('Mandobo Atas (aax) · ISO 639-3')
    end

    it 'leaves a retirement alone when its replacement Code is not published' do
      tajiki = create(:language, code: 'abh', name: 'Arabic, Tajiki')
      collection = create(:collection, languages: [tajiki])

      refresh.run

      expect(tajiki.reload.retired).to be(true)
      expect(collection.reload.languages).to contain_exactly(tajiki)
      expect(Language.find_by(code: 'abv')).to be_nil
      expect(held_section(body_of(ActionMailer::Base.deliveries.sole))).to include("  Retired: code change\n  Tagged: collection_languages 1")
    end

    it 'retires a Code its Source no longer publishes and reinstates a Retired Code it publishes again' do
      vanished = create(:language, code: 'zzz', name: 'Gone')
      akkadian = create(:language, code: 'akk', name: 'Akkadian (retired)', retired: true)
      create(:collection, languages: [vanished])

      refresh.run

      expect(vanished.reload.retired).to be(true)
      expect(akkadian.reload).to have_attributes(retired: false, name: 'Akkadian')

      body = body_of(ActionMailer::Base.deliveries.sole)
      expect(body).to include("Reinstated: 1\n  Akkadian (akk) · ISO 639-3")
      expect(body).to include("Retired and held: 1\n  Gone (zzz) · ISO 639-3")
      expect(held_section(body)).to include("Gone (zzz) · ISO 639-3\n  Retired: no longer published")
    end

    it 'renames a Retired row the old importer suffixed to the name its Source publishes' do
      ayta = create(:language, code: 'aay', name: 'Ayta, Tayabas (retired)', retired: true)

      refresh.run

      expect(ayta.reload).to have_attributes(name: 'Ayta, Tayabas', retired: true)
      expect(body_of(ActionMailer::Base.deliveries.sole)).to include('  Ayta, Tayabas (aay) · ISO 639-3, was Ayta, Tayabas (retired)')
    end

    it 'counts what it retired and who is needed in the subject and the Source section' do
      mandobo = create(:language, code: 'aax', name: 'Mandobo Atas')
      create(:collection, languages: [aariya, mandobo])

      refresh.run

      mail = ActionMailer::Base.deliveries.sole
      expect(mail.subject).to eq(
        '[NABU Admin] Language Refresh: 1 need a person, 0 failures, 33 new, 0 renamed, 2 retired, 0 reinstated'
      )
      expect(body_of(mail)).to include("Retired and rewritten: 1\n  Aariya (aaj) · ISO 639-3 → aar, 1 tag moved")
    end

    it 'attaches every edit link as CSV once a Held Language has more than twenty' do
      mandobo = create(:language, code: 'aax', name: 'Mandobo Atas')
      collection = create(:collection, languages: [mandobo])
      21.times { create(:item, collection:, content_languages: [mandobo], subject_languages: [afar]) }

      refresh.run

      mail = ActionMailer::Base.deliveries.sole
      expect(body_of(mail)).to include('  and 2 more in needs-a-person.csv')

      rows = CSV.parse(mail.attachments['needs-a-person.csv'].decoded, headers: true)
      expect(rows.size).to eq(22)
      expect(rows.first.to_h).to include(
        'source' => 'iso639_3', 'code' => 'aax', 'name' => 'Mandobo Atas', 'reason' => 'split',
        'remedy' => 'Split into Ambrak [aag] and Amal [aad]', 'record' => collection.identifier
      )
    end
  end

  it 'sends a report even when nothing changed' do
    2.times { refresh.run }

    mail = ActionMailer::Base.deliveries.last
    expect(ActionMailer::Base.deliveries.size).to eq(2)
    expect(mail.subject).to eq(
      '[NABU Admin] Language Refresh: 0 need a person, 0 failures, 0 new, 0 renamed, 0 retired, 0 reinstated'
    )
    expect(body_of(mail)).to include(
      "New: 0\n\nRenamed: 0\n\nRetired and rewritten: 0\n\nRetired and held: 0\n\nReinstated: 0\n\nCountry links added: 0"
    )
    expect(mail.attachments).to be_empty
  end

  describe 'a report that cannot be sent' do
    around do |example|
      method, settings = ActionMailer::Base.delivery_method, ActionMailer::Base.smtp_settings
      ActionMailer::Base.delivery_method = :smtp
      ActionMailer::Base.smtp_settings = { address: '127.0.0.1', port: 1 }
      example.run
    ensure
      ActionMailer::Base.delivery_method = method
      ActionMailer::Base.smtp_settings = settings
    end

    it 'marks the Run failed and lets the next Run start' do
      expect { refresh.run }.to raise_error(SystemCallError)

      expect(LanguageRefreshRun.sole).to have_attributes(status: 'failed', finished_at: be_present)
      ActionMailer::Base.delivery_method = :test
      expect(refresh.run).to be_completed
    end
  end

  describe 'fetching a Source' do
    include Sentry::TestHelper

    before { setup_sentry_test }
    after { teardown_sentry_test }

    it 'retries a failed fetch and applies the Source once it answers' do
      stub_request(:get, sil_codes_url).to_timeout.then.to_return(status: 502).then.to_return(body: sil_codes)

      refresh.run

      expect(a_request(:get, sil_codes_url)).to have_been_made.times(3)
      expect(LanguageRefreshRun.sole.sources.dig('iso639_3', 'status')).to eq('applied')
      expect(Language.iso639_3.count).to eq(34)
    end

    it 'fails the stage after three retries, tells Sentry, and still completes the Run and sends the report' do
      stub_request(:get, sil_codes_url).to_return(status: 503)

      refresh.run

      expect(a_request(:get, sil_codes_url)).to have_been_made.times(4)
      expect(Language.count).to eq(0)

      run = LanguageRefreshRun.sole
      expect(run).to be_completed
      expect(run.sources['iso639_3']).to include('status' => 'failed', 'error' => "GET #{sil_codes_url} failed after 4 attempts: HTTP 503")

      expect(sentry_events.size).to eq(1)
      expect(extract_sentry_exceptions(sentry_events.last).map(&:value)).to include(start_with("GET #{sil_codes_url} failed after 4 attempts"))

      mail = ActionMailer::Base.deliveries.sole
      expect(mail.subject).to eq(
        '[NABU Admin] Language Refresh: 0 need a person, 1 failure, 0 new, 0 renamed, 0 retired, 0 reinstated'
      )
      expect(body_of(mail)).to include("Failures\nISO 639-3 failed: GET #{sil_codes_url} failed after 4 attempts: HTTP 503")
    end

    it 'fails the stage when a Source serves something other than its table' do
      stub_request(:get, ethnologue_index_url).to_return(body: '<!DOCTYPE html><html><title>Just a moment...</title></html>')

      refresh.run

      expect(LanguageRefreshRun.sole.sources['iso639_3']).to include('status' => 'failed', 'error' => 'LanguageIndex.tab is missing columns LangID, CountryID')
      expect(Language.count).to eq(0)
    end
  end

  describe 'the in-use Language count', :no_catalog_upload do
    it 'counts the Languages the facet shows and warns once they pass 80% of its cap' do
      stub_const('Oni::SearchCapabilities::LANGUAGE_FACET_LIMIT', 3)
      content, shared, other_content, collection_only, subject_only = create_list(:language, 5)
      collection = create(:collection, languages: [shared, collection_only])
      create(:item, collection:, content_languages: [content, shared], subject_languages: [subject_only])
      create(:item, collection:, content_languages: [other_content, shared], subject_languages: [subject_only])

      refresh.run

      expect(body_of(ActionMailer::Base.deliveries.sole)).to include(
        "In-use Languages\n3 of the 3 the language facet holds.\nWARNING: past 80% of the language facet cap"
      )
    end

    it 'gives the count without a warning below the cap' do
      refresh.run

      body = body_of(ActionMailer::Base.deliveries.sole)
      expect(body).to include("In-use Languages\n0 of the #{Oni::SearchCapabilities::LANGUAGE_FACET_LIMIT} the language facet holds.")
      expect(body).not_to include('WARNING')
    end
  end

  describe 'two Runs at once' do
    # A second database session, as a Run in another process would hold.
    let(:other_session) { ActiveRecord::Base.connection.class.new(ActiveRecord::Base.connection_db_config.configuration_hash) }

    after { other_session.disconnect! }

    it 'lets the second Run exit without running' do
      other_session.select_value("SELECT GET_LOCK('#{described_class::LOCK_NAME}', 0)")

      expect(refresh.run).to be_nil

      expect(LanguageRefreshRun.count).to eq(0)
      expect(Language.count).to eq(0)
      expect(ActionMailer::Base.deliveries).to be_empty
      expect(a_request(:get, sil_codes_url)).not_to have_been_made
    end

    it 'runs again once the other Run lets go' do
      other_session.select_value("SELECT GET_LOCK('#{described_class::LOCK_NAME}', 0)")
      refresh.run
      other_session.select_value("SELECT RELEASE_LOCK('#{described_class::LOCK_NAME}')")

      expect(refresh.run).to be_completed
    end
  end

  describe 'a Source that shrank' do
    let(:header) { sil_codes.lines.first }
    let(:thirty_codes) { header + sil_codes.lines.drop(1).first(30).join }
    let(:twenty_seven_codes) { header + sil_codes.lines.drop(1).first(27).join.sub("\tGhotuo\t", "\tGhotuo Renamed\t") }

    def serve_sil(body)
      stub_request(:get, sil_codes_url).to_return(body:)
    end

    it 'refuses a table 10% smaller than the one the last Run applied, and reports it' do
      serve_sil(thirty_codes)
      refresh.run
      serve_sil(twenty_seven_codes)

      refresh.run

      expect(Language.find_by(code: 'aaa').name).to eq('Ghotuo')
      entry = LanguageRefreshRun.last.sources['iso639_3']
      expect(entry).to include('status' => 'refused', 'rows' => 27, 'error' => '27 rows is 10.0% fewer than the 30 the last applied Run read')
      expect(body_of(ActionMailer::Base.deliveries.last)).to include(
        "Failures\nISO 639-3 refused: 27 rows is 10.0% fewer than the 30 the last applied Run read"
      )
    end

    it 'keeps the last applied Run as the baseline after refusing' do
      serve_sil(thirty_codes)
      refresh.run
      serve_sil(twenty_seven_codes)
      2.times { refresh.run }

      expect(LanguageRefreshRun.last.sources.dig('iso639_3', 'status')).to eq('refused')
    end

    it 'applies the same table on a first Run' do
      serve_sil(twenty_seven_codes)

      refresh.run

      expect(LanguageRefreshRun.sole.sources.dig('iso639_3', 'status')).to eq('applied')
      expect(Language.find_by(code: 'aaa').name).to eq('Ghotuo Renamed')
    end
  end
end
