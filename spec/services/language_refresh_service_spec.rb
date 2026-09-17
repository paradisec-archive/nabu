require 'rails_helper'
require 'sentry/test_helper'

describe LanguageRefreshService do
  let(:fixtures) { Rails.root.join('spec/support/data/language_refresh') }
  let(:sil_codes_url) { LanguageRefresh::IsoStage::SIL_CODES_URL }
  let(:sil_retirements_url) { LanguageRefresh::IsoStage::SIL_RETIREMENTS_URL }
  let(:ethnologue_index_url) { LanguageRefresh::IsoStage::ETHNOLOGUE_INDEX_URL }
  let(:sil_codes) { fixtures.join('iso-639-3.tab').read }
  let(:stages) { [LanguageRefresh::IsoStage] }
  let(:refresh) { described_class.new(fetcher: LanguageRefresh::Fetcher.new(backoff: 0), stages:) }

  let(:releases_url) { LanguageRefresh::GlottologStage::RELEASES_URL }
  let(:glottolog_url) { format(LanguageRefresh::GlottologStage::LANGUAGES_URL, 'v5.3') }
  let(:glottolog_languages) { fixtures.join('glottolog-languages.csv').read }

  let(:austlang_url) { %r{\Ahttps://data\.gov\.au/data/api/3/action/datastore_search\?} }
  let(:austlang_dataset) { fixtures.join('austlang-datastore.json').read }

  let!(:australia) { create(:country, code: 'AU', name: 'Australia') }
  let!(:papua_new_guinea) { create(:country, code: 'PG', name: 'Papua New Guinea') }
  let!(:vanuatu) { create(:country, code: 'VU', name: 'Vanuatu') }
  let!(:united_states) { create(:country, code: 'US', name: 'United States') }

  def body_of(mail)
    (mail.text_part || mail.body).decoded
  end

  before do
    stub_request(:get, sil_codes_url).to_return(body: sil_codes, headers: { 'Last-Modified' => 'Wed, 22 Jul 2026 17:03:19 GMT' })
    stub_request(:get, sil_retirements_url)
      .to_return(body: fixtures.join('iso-639-3_Retirements.tab').read, headers: { 'Last-Modified' => 'Mon, 13 Jul 2026 04:12:00 GMT' })
    stub_request(:get, ethnologue_index_url)
      .to_return(body: fixtures.join('LanguageIndex.tab').read, headers: { 'Last-Modified' => 'Fri, 27 Feb 2026 21:59:51 GMT' })
    stub_request(:get, releases_url).to_return(body: { tag_name: 'v5.3' }.to_json)
    stub_request(:get, glottolog_url).to_return(body: glottolog_languages)
    stub_request(:get, austlang_url).to_return(body: austlang_dataset)
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
      expect(run.sources.dig('iso639_3', 'changes', 'renamed')).to eq([{ 'code' => 'tpi', 'name' => 'Tok Pisin', 'old_name' => 'Pisin, Tok' }])
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

    # The old importer, and an admin before the box-only form, could both set the flag without moving
    # the tags, so the rewrite is owed whatever set it.
    it 'rewrites a one-to-one retirement whose row was already flagged Retired' do
      aariya.update!(retired: true)
      collection = create(:collection, languages: [aariya])

      refresh.run

      expect(collection.reload.languages).to contain_exactly(afar)

      body = body_of(ActionMailer::Base.deliveries.sole)
      expect(body).to include("Retired and rewritten: 1\n  Aariya (aaj) · ISO 639-3 → aar, 1 tag moved")
      expect(held_section(body)).to eq("Needs a person\nNothing needs a person.\n\nFailures")
    end

    it 'says nothing more about an old one-to-one retirement once its tags have moved' do
      aariya.update!(retired: true)
      create(:collection, languages: [aariya])

      refresh.run
      refresh.run

      expect(body_of(ActionMailer::Base.deliveries.last)).to include('Retired and rewritten: 0')
    end

    # Held is read from the database rather than from the stages, so a Source that answered nothing
    # this Run cannot drop its Languages off the list.
    it 'lists a Retired Language still tagged even when its Source failed' do
      mandobo = create(:language, code: 'aax', name: 'Mandobo Atas', retired: true)
      create(:collection, languages: [mandobo])
      stub_request(:get, sil_codes_url).to_return(status: 503)

      refresh.run

      mail = ActionMailer::Base.deliveries.sole
      expect(mail.subject).to include('1 need a person', '1 failure')
      expect(held_section(body_of(mail))).to include("Mandobo Atas (aax) · ISO 639-3\n  Retired: no longer published")
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
    let(:lock) { described_class.lock_name(ActiveRecord::Base.connection.current_database) }

    after { other_session.disconnect! }

    it 'names the database in the lock, so a Run against another database does not hold this one off' do
      expect(described_class.lock_name('nabu_other')).to eq('nabu_language_refresh_nabu_other')
      expect(described_class.lock_name('nabu_other')).not_to eq(described_class.lock_name('nabu_elsewhere'))
    end

    it 'keeps the lock within the length MySQL allows when the database name is long' do
      long = "nabu_test_#{'a' * 60}"

      expect(described_class.lock_name(long).length).to be <= described_class::LOCK_NAME_LIMIT
      expect(described_class.lock_name(long)).not_to eq(described_class.lock_name("#{long}_2"))
    end

    it 'lets the second Run exit without running' do
      other_session.select_value("SELECT GET_LOCK('#{lock}', 0)")

      expect(refresh.run).to be_nil

      expect(LanguageRefreshRun.count).to eq(0)
      expect(Language.count).to eq(0)
      expect(ActionMailer::Base.deliveries).to be_empty
      expect(a_request(:get, sil_codes_url)).not_to have_been_made
    end

    it 'runs again once the other Run lets go' do
      other_session.select_value("SELECT GET_LOCK('#{lock}', 0)")
      refresh.run
      other_session.select_value("SELECT RELEASE_LOCK('#{lock}')")

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

  describe 'the Glottolog stage' do
    let(:stages) { [LanguageRefresh::GlottologStage] }

    it 'takes every language and dialect, and never a family or anything under Bookkeeping' do
      refresh.run

      expect(Language.glottolog.pluck(:code)).to contain_exactly('warl1254', 'sout2762', 'ngar1284', 'unse1236', 'paya1237')
      expect(Language.find_by(code: 'sout2762')).to have_attributes(name: 'Southern Warlpiri', dialect: true)
      expect(Language.find_by(code: 'warl1254')).to have_attributes(name: 'Warlpiri', dialect: false)
    end

    it 'fills a box from the Source point and leaves a Language Glottolog gives no point for boxless' do
      refresh.run

      expect(Language.find_by(code: 'warl1254')).to have_attributes(
        north_limit: be_within(0.001).of(-20.1008), south_limit: be_within(0.001).of(-20.1008),
        west_limit: be_within(0.001).of(131.05), east_limit: be_within(0.001).of(131.05)
      )
      expect(Language.find_by(code: 'paya1237'))
        .to have_attributes(north_limit: nil, south_limit: nil, west_limit: nil, east_limit: nil)
    end

    it 'links each Language to the countries Glottolog lists for it' do
      refresh.run

      expect(Language.find_by(code: 'warl1254').countries).to contain_exactly(australia)
      expect(Language.find_by(code: 'unse1236').countries).to contain_exactly(australia, papua_new_guinea)
      expect(Language.find_by(code: 'paya1237').countries).to contain_exactly(united_states)
      expect(Language.find_by(code: 'sout2762').countries).to be_empty
    end

    it 'reads the release tag from the API rather than a branch, and records it' do
      refresh.run

      expect(a_request(:get, releases_url)).to have_been_made
      expect(LanguageRefreshRun.sole.sources['glottolog']).to include(
        'status' => 'applied', 'version' => { 'languages.csv' => 'Glottolog 5.3' }, 'rows' => 5
      )
      expect(body_of(ActionMailer::Base.deliveries.sole))
        .to include("Glottolog\nStatus: applied\nVersions: languages.csv Glottolog 5.3\nRows read: 5")
    end

    it 'fails the stage when the releases API names no tag' do
      stub_request(:get, releases_url).to_return(body: '{}')

      refresh.run

      expect(LanguageRefreshRun.sole.sources['glottolog'])
        .to include('status' => 'failed', 'error' => "#{releases_url} named no release tag")
      expect(Language.glottolog.count).to eq(0)
    end

    it 'fails the stage when the CSV is not the table Glottolog publishes' do
      stub_request(:get, glottolog_url).to_return(body: "ID,Name\nwarl1254,Warlpiri\n")

      refresh.run

      expect(LanguageRefreshRun.sole.sources['glottolog'])
        .to include(
          'status' => 'failed',
          'error' => 'languages.csv is missing columns Level, Countries, Family_ID, Latitude, Longitude, ISO639P3code, Closest_ISO369P3code'
        )
    end

    it 'reads a dialect as a Glottolog dialect wherever the report names it' do
      refresh.run

      expect(body_of(ActionMailer::Base.deliveries.sole)).to include('  Southern Warlpiri (sout2762) · Glottolog dialect')
    end

    it 'reports a box it filled on a Language that already existed without one' do
      existing = create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri')

      refresh.run

      expect(existing.reload.north_limit).to be_within(0.001).of(-20.1008)
      expect(body_of(ActionMailer::Base.deliveries.sole))
        .to include("Bounding boxes filled from the Source point: 1\n  Warlpiri (warl1254) · Glottolog")
    end

    describe 'a point that disagrees with a box someone already set' do
      let(:sydney_box) { { north_limit: -33.8, south_limit: -33.9, west_limit: 151.1, east_limit: 151.3 } }

      it 'warns how far outside the box the point lies and leaves the box alone' do
        warlpiri = create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri', **sydney_box)

        refresh.run

        expect(warlpiri.reload).to have_attributes(**sydney_box)
        expect(body_of(ActionMailer::Base.deliveries.sole)).to include(
          "Location warnings: 1\n  Warlpiri (warl1254) · Glottolog, the Source point is 2496 km outside the Bounding box"
        )
      end

      it 'raises the same warning again on the next Run' do
        create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri', **sydney_box)
        refresh.run
        ActionMailer::Base.deliveries.clear

        refresh.run

        expect(body_of(ActionMailer::Base.deliveries.sole)).to include('Location warnings: 1')
      end

      it 'raises no warning for a point inside the box' do
        create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri',
                                      north_limit: -19.0, south_limit: -21.0, west_limit: 130.0, east_limit: 132.0)

        refresh.run

        expect(body_of(ActionMailer::Base.deliveries.sole)).to include('Location warnings: 0')
      end

      # 250 km is 2.248 degrees of latitude, so these two boxes sit either side of the threshold:
      # the point is 249 km north of the first and 250 km north of the second.
      it 'raises no warning for a point outside the box but nearer than 250 km' do
        create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri',
                                      north_limit: -22.34, south_limit: -24.0, west_limit: 130.0, east_limit: 132.0)

        refresh.run

        expect(body_of(ActionMailer::Base.deliveries.sole)).to include('Location warnings: 0')
      end

      it 'warns for a point just past 250 km' do
        create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri',
                                      north_limit: -22.35, south_limit: -24.0, west_limit: 130.0, east_limit: 132.0)

        refresh.run

        expect(body_of(ActionMailer::Base.deliveries.sole)).to include('the Source point is 250 km outside the Bounding box')
      end

      it 'raises no warning for a point inside a box that crosses the antimeridian' do
        stub_request(:get, glottolog_url)
          .to_return(body: glottolog_languages.sub('-20.1008,131.05,warl1254', '-18.0,-179.0,warl1254'))
        create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri',
                                      north_limit: -17.0, south_limit: -19.0, west_limit: 177.0, east_limit: -178.0)

        refresh.run

        expect(body_of(ActionMailer::Base.deliveries.sole)).to include('Location warnings: 0')
      end

      it 'takes the Language but no box when the Source publishes a coordinate it cannot read' do
        stub_request(:get, glottolog_url)
          .to_return(body: glottolog_languages.sub('-20.1008,131.05,warl1254', 'hereabouts,131.05,warl1254'))

        refresh.run

        expect(LanguageRefreshRun.sole.sources.dig('glottolog', 'status')).to eq('applied')
        expect(Language.find_by(code: 'warl1254')).to have_attributes(name: 'Warlpiri', north_limit: nil, west_limit: nil)
      end

      it 'neither fills nor warns when only some of the four limits are set' do
        warlpiri = create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri', north_limit: -33.8, south_limit: -33.9)

        refresh.run

        expect(warlpiri.reload).to have_attributes(north_limit: -33.8, west_limit: nil)
        body = body_of(ActionMailer::Base.deliveries.sole)
        expect(body).to include('Bounding boxes filled from the Source point: 0')
        expect(body).to include('Location warnings: 0')
      end
    end

    it 'reinstates a glottocode Glottolog publishes again' do
      refresh.run
      warlpiri = Language.find_by(code: 'warl1254')
      warlpiri.update!(retired: true)
      ActionMailer::Base.deliveries.clear

      refresh.run

      expect(warlpiri.reload.retired).to be(false)
      expect(body_of(ActionMailer::Base.deliveries.sole)).to include("Reinstated: 1\n  Warlpiri (warl1254) · Glottolog")
    end

    it 'retires a glottocode that has gone and lists it under needs a person while it is still tagged' do
      refresh.run
      ngarinyin = Language.find_by(code: 'ngar1284')
      create(:collection, languages: [ngarinyin])
      stub_request(:get, glottolog_url).to_return(body: glottolog_languages.lines.grep_v(/\Angar1284,/).join)
      stub_const('LanguageRefreshService::SHRINK_LIMIT', 0.5)
      ActionMailer::Base.deliveries.clear

      refresh.run

      expect(ngarinyin.reload.retired).to be(true)
      body = body_of(ActionMailer::Base.deliveries.sole)
      expect(body).to include("Retired and held: 1\n  Ngarinyin (ngar1284) · Glottolog")
      expect(body).to include("Ngarinyin (ngar1284) · Glottolog\n  Retired: no longer published\n  Tagged: collection_languages 1")
    end

    describe 'a second Run against a changed release' do
      let(:changed) do
        glottolog_languages
          .sub('ngar1284,Ngarinyin,', 'ngar1284,Ngarinjin,')
          .sub('-20.1008,131.05,warl1254', '-19.5,130.0,warl1254')
          .sub('sout2762,,dialect,', 'sout2762,,language,')
          .sub('AU;PG,indo1319,', 'AU;PG,book1242,')
      end

      before do
        refresh.run
        stub_request(:get, glottolog_url).to_return(body: changed)
        stub_const('LanguageRefreshService::SHRINK_LIMIT', 0.5)
        ActionMailer::Base.deliveries.clear
      end

      it 'applies a rename, a dialect reclassification and retires a language moved into Bookkeeping' do
        refresh.run

        expect(Language.find_by(code: 'ngar1284').name).to eq('Ngarinjin')
        expect(Language.find_by(code: 'sout2762').dialect).to be(false)
        expect(Language.find_by(code: 'unse1236')).to have_attributes(retired: true, name: 'Unserdeutsch')

        body = body_of(ActionMailer::Base.deliveries.sole)
        expect(body).to include("Renamed: 1\n  Ngarinjin (ngar1284) · Glottolog, was Ngarinyin")
        expect(body).to include("Dialect flag changed: 1\n  Southern Warlpiri (sout2762) · Glottolog")
        expect(body).to include("Retired and held: 1\n  Unserdeutsch (unse1236) · Glottolog")
      end

      # The Bounding box is the only thing a Source does not own, so a point that has moved is never
      # applied over one. This one has moved 129 km, too little to be worth a person's time.
      it 'never moves a box that already exists, and says nothing of a point that moved a little' do
        refresh.run

        expect(Language.find_by(code: 'warl1254').north_limit).to be_within(0.001).of(-20.1008)
        body = body_of(ActionMailer::Base.deliveries.sole)
        expect(body).to include('Bounding boxes filled from the Source point: 0')
        expect(body).to include('Location warnings: 0')
      end
    end
  end

  describe 'the AUSTLANG stage' do
    let(:stages) { [LanguageRefresh::AustlangStage] }

    def serve_austlang
      payload = JSON.parse(austlang_dataset)
      yield payload['result']['records']
      payload['result']['total'] = payload['result']['records'].size
      stub_request(:get, austlang_url).to_return(body: payload.to_json)
    end

    it 'takes every Language the datastore publishes, in one call' do
      refresh.run

      expect(Language.austlang.pluck(:code)).to contain_exactly('C15', 'G5', 'A38.1', 'N116.A', 'A10', 'C41')
      expect(Language.find_by(code: 'C15', source: :austlang)).to have_attributes(name: 'Warlpiri', dialect: false, retired: false)
      expect(a_request(:get, austlang_url)).to have_been_made.once
    end

    it 'fills a box from the published point and leaves a Language published at 0,0 boxless' do
      refresh.run

      expect(Language.find_by(code: 'C15', source: :austlang)).to have_attributes(
        north_limit: be_within(0.001).of(-20.4336), south_limit: be_within(0.001).of(-20.4336),
        west_limit: be_within(0.001).of(131.0524), east_limit: be_within(0.001).of(131.0524)
      )
      expect(Language.find_by(code: 'A38.1', source: :austlang))
        .to have_attributes(north_limit: nil, south_limit: nil, west_limit: nil, east_limit: nil)
    end

    it 'links every Language to Australia' do
      refresh.run

      expect(Language.austlang.map { |language| language.countries.to_a }).to all(eq([australia]))
    end

    it 'records the version and the counts on the Run and prints them in the report' do
      refresh.run

      expect(LanguageRefreshRun.sole.sources['austlang']).to include(
        'status' => 'applied', 'version' => { 'austlang_dataset' => a_string_starting_with('sha256:') }, 'rows' => 6,
        'counts' => { 'country_links_added' => 6 }
      )
      body = body_of(ActionMailer::Base.deliveries.sole)
      expect(body).to match(/AUSTLANG\nStatus: applied\nVersions: austlang_dataset sha256:\h{12}\nRows read: 6/)
      expect(body).to include("New: 6\n  Warlpiri (C15) · AUSTLANG")
      expect(body).to include("Country links added: 6\n")
    end

    it 'gives a new version when the dataset changes, so a Run can tell one download from the next' do
      refresh.run
      first = LanguageRefreshRun.sole.sources.dig('austlang', 'version')
      serve_austlang { |records| records.first['language_name'] = 'Walpiri' }

      refresh.run

      expect(LanguageRefreshRun.last.sources.dig('austlang', 'version')).not_to eq(first)
    end

    describe 'a second Run against a changed dataset' do
      before { refresh.run }

      it 'applies and reports a rename' do
        serve_austlang { |records| records.first['language_name'] = 'Walpiri' }
        ActionMailer::Base.deliveries.clear

        refresh.run

        expect(Language.find_by(code: 'C15', source: :austlang).name).to eq('Walpiri')
        expect(body_of(ActionMailer::Base.deliveries.sole)).to include("Renamed: 1\n  Walpiri (C15) · AUSTLANG, was Warlpiri")
      end

      it 'fills a box on a Language AUSTLANG has since given a point for' do
        serve_austlang do |records|
          record = records.find { |row| row['language_code'] == 'A38.1' }
          record['approximate_latitude_of_language_variety'] = -26.0
          record['approximate_longitude_of_language_variety'] = 126.0
        end
        ActionMailer::Base.deliveries.clear

        refresh.run

        expect(Language.find_by(code: 'A38.1', source: :austlang).north_limit).to be_within(0.001).of(-26.0)
        expect(body_of(ActionMailer::Base.deliveries.sole))
          .to include("Bounding boxes filled from the Source point: 1\n  Widjandja (A38.1) · AUSTLANG")
      end

      # A box is a person's to change once it exists, so a point that has moved is never applied over
      # one. Reporting the disagreement is #1213's Location warning.
      it 'never moves a box that already exists' do
        serve_austlang { |records| records.first['approximate_latitude_of_language_variety'] = -30.0 }
        ActionMailer::Base.deliveries.clear

        refresh.run

        expect(Language.find_by(code: 'C15', source: :austlang).north_limit).to be_within(0.001).of(-20.4336)
        expect(body_of(ActionMailer::Base.deliveries.sole)).to include('Bounding boxes filled from the Source point: 0')
      end

      it 'retires a Code AUSTLANG no longer publishes and rewrites nothing' do
        warlpiri = Language.find_by(code: 'C15', source: :austlang)
        item = create(:item, content_languages: [warlpiri])
        serve_austlang { |records| records.reject! { |row| row['language_code'] == 'C15' } }
        stub_const('LanguageRefreshService::SHRINK_LIMIT', 0.5)
        ActionMailer::Base.deliveries.clear

        refresh.run

        expect(warlpiri.reload).to have_attributes(retired: true, name: 'Warlpiri')
        expect(item.reload.content_languages).to eq([warlpiri])
        expect(body_of(ActionMailer::Base.deliveries.sole)).to include("Retired and held: 1\n  Warlpiri (C15) · AUSTLANG")
      end

      it 'lists a Retired Language under needs a person while it is still tagged' do
        warlpiri = Language.find_by(code: 'C15', source: :austlang)
        create(:item, content_languages: [warlpiri])
        serve_austlang { |records| records.reject! { |row| row['language_code'] == 'C15' } }
        stub_const('LanguageRefreshService::SHRINK_LIMIT', 0.5)
        ActionMailer::Base.deliveries.clear

        refresh.run

        body = body_of(ActionMailer::Base.deliveries.sole)
        expect(body).to include(
          "Warlpiri (C15) · AUSTLANG\n  Retired: no longer published\n  Tagged: collection_languages 1, item_content_languages 1"
        )
      end

      it 'reinstates a Code AUSTLANG publishes again' do
        warlpiri = Language.find_by(code: 'C15', source: :austlang)
        warlpiri.update!(retired: true)
        ActionMailer::Base.deliveries.clear

        refresh.run

        expect(warlpiri.reload.retired).to be(false)
        expect(body_of(ActionMailer::Base.deliveries.sole)).to include("Reinstated: 1\n  Warlpiri (C15) · AUSTLANG")
      end
    end

    describe 'a point that disagrees with a box' do
      it 'warns rather than moving a box a person already has, and says how far out the point is' do
        # Warlpiri is published at -20.4336, 131.0524; this box is over Sydney.
        warlpiri = create(:language, :austlang, code: 'C15', name: 'Warlpiri',
                                                north_limit: -33.0, south_limit: -34.0, west_limit: 150.0, east_limit: 151.0)

        refresh.run

        expect(warlpiri.reload).to have_attributes(north_limit: -33.0, south_limit: -34.0, west_limit: 150.0, east_limit: 151.0)
        expect(body_of(ActionMailer::Base.deliveries.sole))
          .to match(/Location warnings: 1\n  Warlpiri \(C15\) · AUSTLANG, the Source point is \d+ km outside the Bounding box/)
      end

      it 'raises no warning for a Language AIATSIS publishes at 0,0' do
        create(:language, :austlang, code: 'A10', name: 'Ngurlu',
                                     north_limit: -33.0, south_limit: -34.0, west_limit: 150.0, east_limit: 151.0)

        refresh.run

        expect(body_of(ActionMailer::Base.deliveries.sole)).to include('Location warnings: 0')
      end
    end

    describe 'a datastore that does not answer the table' do
      def failure
        refresh.run
        LanguageRefreshRun.last.sources['austlang']
      end

      it 'fails the stage when CKAN reports no success' do
        stub_request(:get, austlang_url).to_return(body: { success: false, error: { message: 'Not found: Resource' } }.to_json)

        expect(failure).to include('status' => 'failed', 'error' => 'datastore_search refused the request: Not found: Resource')
        expect(Language.austlang.count).to eq(0)
      end

      it 'fails the stage when the table is missing a column the stage reads' do
        stub_request(:get, austlang_url).to_return(
          body: { success: true, result: { fields: [{ id: 'language_code' }], records: [], total: 0 } }.to_json
        )

        expect(failure).to include(
          'status' => 'failed',
          'error' => 'datastore_search is missing columns language_name, ' \
                     'approximate_latitude_of_language_variety, approximate_longitude_of_language_variety'
        )
      end

      it 'fails the stage rather than retire every Language the page left out' do
        payload = JSON.parse(austlang_dataset)
        payload['result']['records'] = payload['result']['records'].first(2)
        stub_request(:get, austlang_url).to_return(body: payload.to_json)

        expect(failure).to include('status' => 'failed', 'error' => 'datastore_search answered 2 of 6 rows')
      end

      it 'fails the stage when the datastore answers something other than JSON' do
        stub_request(:get, austlang_url).to_return(body: '<html>Gateway timeout</html>')

        expect(failure).to include('status' => 'failed', 'error' => a_string_including('did not answer with JSON'))
      end
    end
  end

  describe 'the Equivalents stage' do
    let(:stages) { described_class::STAGES }
    let(:warlpiri) { Language.find_by(code: 'wbp', source: :iso639_3) }
    let(:glottolog_warlpiri) { Language.find_by(code: 'warl1254', source: :glottolog) }
    let(:southern_warlpiri) { Language.find_by(code: 'sout2762', source: :glottolog) }
    let(:austlang_warlpiri) { Language.find_by(code: 'C15', source: :austlang) }
    let(:yarlpiri) { Language.find_by(code: 'C41', source: :austlang) }

    before { stub_const('LanguageRefresh::EquivalentsStage::CHIRILA_FILE', fixtures.join('chirila-codes.csv')) }

    def evidence_between(one, other)
      language_id, related_language_id = LanguageEquivalent.ordered_pair(one.id, other.id)
      LanguageEquivalent.find_by(language_id:, related_language_id:)&.evidence
    end

    def rename_austlang_warlpiri
      payload = JSON.parse(austlang_dataset)
      payload['result']['records'].first['language_name'] = 'Walpiri'
      stub_request(:get, austlang_url).to_return(body: payload.to_json)
    end

    it 'pairs a Glottolog Language with the ISO Code it names, accumulating the evidence of a shared name' do
      refresh.run

      expect(evidence_between(glottolog_warlpiri, warlpiri)).to eq(['glottolog:iso', 'name'])
    end

    it 'pairs a Glottolog dialect with the closest ISO Code Glottolog names for it' do
      refresh.run

      expect(evidence_between(southern_warlpiri, warlpiri)).to eq(['glottolog:closest_iso'])
    end

    it 'pairs an AUSTLANG Language with the ISO Code and the glottocode Chirila names beside it' do
      refresh.run

      expect(evidence_between(yarlpiri, warlpiri)).to eq(['chirila:iso'])
      expect(evidence_between(yarlpiri, glottolog_warlpiri)).to eq(['chirila:glottocode'])
    end

    it 'pairs two Sources that publish the same name' do
      refresh.run

      expect(evidence_between(austlang_warlpiri, warlpiri)).to eq(['name'])
      expect(evidence_between(austlang_warlpiri, glottolog_warlpiri)).to eq(['name'])
    end

    it 'takes no pair a Source names against a Code no Source holds' do
      refresh.run

      expect(LanguageEquivalent.count).to eq(6)
      expect(Language.find_by(code: 'ngar1284', source: :glottolog).equivalents).to be_empty
    end

    it 'writes the whole table again on the next Run, dropping a pair whose evidence has gone' do
      refresh.run
      rename_austlang_warlpiri

      refresh.run

      expect(evidence_between(austlang_warlpiri, warlpiri)).to be_nil
      expect(evidence_between(austlang_warlpiri, glottolog_warlpiri)).to be_nil
      expect(evidence_between(glottolog_warlpiri, warlpiri)).to eq(['glottolog:iso', 'name'])
      expect(LanguageEquivalent.count).to eq(4)
    end

    it "downloads Glottolog's table once for the Run, though two stages read it" do
      refresh.run

      expect(a_request(:get, glottolog_url)).to have_been_made.once
    end

    it 'writes no PaperTrail versions' do
      expect { refresh.run }.not_to(change { PaperTrail::Version.where(item_type: 'LanguageEquivalent').count })
    end

    it 'records what it read and the pairs it wrote in the Run and the report' do
      refresh.run

      expect(LanguageRefreshRun.sole.sources['equivalents']).to include(
        'status' => 'applied',
        'version' => {
          'chirila-codes.csv' => LanguageRefresh::EquivalentsStage::CHIRILA_VERSION, 'languages.csv' => 'Glottolog 5.3'
        },
        'rows' => 3,
        'counts' => {
          'pairs' => 6, 'glottolog_iso' => 1, 'glottolog_closest_iso' => 1, 'chirila_iso' => 1, 'chirila_glottocode' => 1, 'name' => 3
        }
      )
      expect(body_of(ActionMailer::Base.deliveries.sole)).to include(
        "Equivalents\nStatus: applied\n" \
        "Versions: chirila-codes.csv #{LanguageRefresh::EquivalentsStage::CHIRILA_VERSION}, languages.csv Glottolog 5.3\n" \
        "Rows read: 3\n\nPairs: 6\nGlottolog iso: 1\nGlottolog closest iso: 1\n" \
        "Chirila iso: 1\nChirila glottocode: 1\nName: 3"
      )
    end
  end

  describe 'every Source' do
    let(:stages) { described_class::STAGES }

    # MySQL normalises the keys of a JSON object by length, so a Run records which Sources ran but
    # never the order they ran in.
    it 'applies every Source in one Run' do
      refresh.run

      expect(LanguageRefreshRun.sole.sources.keys).to contain_exactly('iso639_3', 'glottolog', 'austlang', 'equivalents')
      expect(Language.iso639_3.count).to eq(34)
      expect(Language.glottolog.count).to eq(5)
      expect(Language.austlang.count).to eq(6)
    end

    it 'leaves the other Sources applied when the AUSTLANG datastore does not answer' do
      stub_request(:get, austlang_url).to_return(status: 503)

      refresh.run

      run = LanguageRefreshRun.sole
      expect(run).to be_completed
      expect(run.sources.dig('iso639_3', 'status')).to eq('applied')
      expect(run.sources.dig('glottolog', 'status')).to eq('applied')
      expect(run.sources.dig('austlang', 'status')).to eq('failed')
      expect(run.sources.dig('equivalents', 'status')).to eq('applied')
      expect(Language.austlang.count).to eq(0)
      expect(body_of(ActionMailer::Base.deliveries.sole)).to include("Failures\nAUSTLANG failed: GET ")
    end

    # The Equivalents stage reads Glottolog's table too, so it fails with it rather than regenerate
    # the table without the pairs that column seeds.
    it 'fails the Glottolog and Equivalents stages when the releases API does not answer' do
      stub_request(:get, releases_url).to_return(status: 503)

      refresh.run

      run = LanguageRefreshRun.sole
      expect(run).to be_completed
      expect(run.sources.dig('iso639_3', 'status')).to eq('applied')
      expect(run.sources.dig('glottolog', 'status')).to eq('failed')
      expect(run.sources.dig('equivalents', 'status')).to eq('failed')
      expect(Language.iso639_3.count).to eq(34)
      expect(Language.glottolog.count).to eq(0)
      expect(body_of(ActionMailer::Base.deliveries.sole)).to include("Failures\nGlottolog failed: GET #{releases_url}")
    end
  end
end
