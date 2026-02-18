require 'uri'
require 'net/http'

# Audits DOI URLs registered with DataCite against expected repository URLs.
# Optionally updates mismatched DOIs when run with update: true.
#
# Usage:
#   DoiUrlAuditService.run                        # report only
#   DoiUrlAuditService.run(update: true)           # report and update
#   DoiUrlAuditService.run(paged: true)            # report page-by-page with prompts
#   DoiUrlAuditService.run(update: true, paged: true) # update page-by-page with prompts
#   DoiUrlAuditService.fix_one('10.26278/XXXX')       # fix a single DOI
class DoiUrlAuditService
  def self.run(update: false, paged: false)
    new(update:, paged:).run
  end

  def self.fix_one(doi)
    new.fix_one(doi)
  end

  def initialize(update: false, paged: false)
    @base_url = ENV.fetch('DATACITE_BASE_URL')
    @user = ENV.fetch('DATACITE_USER')
    @pass = ENV.fetch('DATACITE_PASS')
    @prefix = ENV.fetch('DOI_PREFIX')
    @update = update
    @paged = paged
  end

  def run
    @run_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    puts "DOI URL Audit started at #{Time.current}"
    puts "Mode: #{@update ? 'UPDATE' : 'REPORT ONLY'}#{@paged ? ' (paged)' : ''}"

    @db_index = timed('Building DB index') { build_db_index }
    puts "  #{@db_index.size} DOIs found in database"

    if @paged
      run_paged
    else
      run_batch
    end

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @run_start).round(1)
    puts "DOI URL Audit finished at #{Time.current} (total: #{elapsed}s)"
  end

  def fix_one(doi)
    record = find_record_by_doi(doi)
    unless record
      puts "DOI #{doi} not found in database"

      return
    end

    expected_url = record.full_path
    puts "Found: #{record.class} (#{record.full_identifier})"
    puts "  Expected URL: #{expected_url}"

    response = datacite_get_url("#{@base_url}/dois/#{doi}")
    unless response
      puts "DOI #{doi} not found in DataCite"

      return
    end

    current_url = response.dig('data', 'attributes', 'url')
    current_state = response.dig('data', 'attributes', 'state')
    current_schema = response.dig('data', 'attributes', 'schemaVersion')
    current_contributors = response.dig('data', 'attributes', 'contributors') || []
    expected_state = record_public?(record) ? 'findable' : 'registered'
    puts "  Current URL:  #{current_url}"
    puts "  State:        #{current_state} (expected: #{expected_state})"
    puts "  Schema:       #{current_schema || 'unknown'}"

    if current_url == expected_url
      puts 'URLs already match, nothing to do.'

      return
    end

    unless catalog_url?(current_url)
      puts "Current URL is not on catalog.paradisec.org.au, skipping."

      return
    end

    print 'Update this DOI? [y/N] '
    answer = $stdin.gets&.strip&.downcase

    return unless answer == 'y'

    body = build_update_body(record, current_contributors:)

    if datacite_put("/dois/#{doi}", body)
      puts "Updated DOI #{doi} to #{expected_url}"
    else
      puts "Failed to update DOI #{doi}"
    end
  end

  private

  def find_record_by_doi(doi)
    Collection.find_by(doi:) || Item.find_by(doi:) || Essence.find_by(doi:)
  end

  def run_batch
    datacite_dois = timed('Fetching all DataCite DOIs') { fetch_all_datacite_dois }
    puts "  #{datacite_dois.size} DOIs fetched"

    results = timed('Cross-referencing') { cross_reference(datacite_dois) }
    print_report(results, datacite_dois.size)

    timed('Updating DOIs') { update_dois(results[:needs_update]) } if @update
  end

  def run_paged
    totals = { correct: 0, needs_update: 0, unexpected_url: 0, state_mismatch: 0, orphaned: 0, fetched: 0 }
    next_url = "#{@base_url}/dois?prefix=#{@prefix}&page[size]=#{page_size}&page[cursor]=1"
    pages_fetched = 0

    while next_url
      response = timed('Fetching DataCite page') { datacite_get_url(next_url) }
      unless response
        Rails.logger.error 'Failed to fetch DataCite DOIs'
        break
      end

      page_dois = parse_doi_records(response)
      break if page_dois.empty?

      pages_fetched += 1
      total = response.dig('meta', 'total') || 0
      totals[:fetched] += page_dois.size

      results = timed('Cross-referencing page') { cross_reference(page_dois) }

      puts "\n--- Page #{pages_fetched} (#{totals[:fetched]}/#{total} DOIs) ---"
      print_report(results, page_dois.size)

      timed('Updating page DOIs') { update_dois(results[:needs_update]) } if @update

      totals[:correct] += results[:correct].size
      totals[:needs_update] += results[:needs_update].size
      totals[:unexpected_url] += results[:unexpected_url].size
      totals[:state_mismatch] += results[:state_mismatch].size
      totals[:orphaned] += results[:orphaned].size

      next_url = response.dig('links', 'next')
      break unless next_url

      print 'Continue to next page? [Y/n] '
      answer = $stdin.gets&.strip&.downcase
      break if answer == 'n'

      sleep(0.5)
    end

    puts "\n#{'=' * 60}"
    puts 'Cumulative Totals'
    puts '=' * 60
    puts "  Pages fetched: #{pages_fetched}"
    puts "  DOIs fetched: #{totals[:fetched]}"
    puts "  Correct: #{totals[:correct]}"
    puts "  Needs update: #{totals[:needs_update]}"
    puts "  Unexpected URL (skipped): #{totals[:unexpected_url]}"
    puts "  State mismatch: #{totals[:state_mismatch]}"
    puts "  Orphaned: #{totals[:orphaned]}"
    puts '=' * 60
  end

  def build_db_index
    index = {}

    timed('  Collections') do
      count = 0
      Collection.where.not(doi: nil).find_each do |collection|
        index[collection.doi.downcase] = {
          type: 'Collection',
          record: collection,
          expected_url: collection.full_path,
          expected_state: collection.private? ? 'registered' : 'findable'
        }
        count += 1
        print_progress(count)
      end
      print_progress_done(count)
    end

    timed('  Items') do
      count = 0
      Item.where.not(doi: nil).includes(:collection).find_each do |item|
        index[item.doi.downcase] = {
          type: 'Item',
          record: item,
          expected_url: item.full_path,
          expected_state: item.public? ? 'findable' : 'registered'
        }
        count += 1
        print_progress(count)
      end
      print_progress_done(count)
    end

    timed('  Essences') do
      count = 0
      Essence.where.not(doi: nil).includes(item: :collection).find_each do |essence|
        index[essence.doi.downcase] = {
          type: 'Essence',
          record: essence,
          expected_url: essence.full_path,
          expected_state: essence.item.public? ? 'findable' : 'registered'
        }
        count += 1
        print_progress(count)
      end
      print_progress_done(count)
    end

    index
  end

  def page_size
    1000
  end

  def fetch_all_datacite_dois
    dois = []
    # Cursor-based pagination has no upper limit (page-number is capped at 10,000 records)
    next_url = "#{@base_url}/dois?prefix=#{@prefix}&page[size]=#{page_size}&page[cursor]=1"
    pages_fetched = 0

    while next_url
      response = timed("  Fetching page #{pages_fetched + 1}") { datacite_get_url(next_url) }
      unless response
        Rails.logger.error 'Failed to fetch DataCite DOIs'
        break
      end

      page_dois = parse_doi_records(response)
      break if page_dois.empty?

      pages_fetched += 1
      dois.concat(page_dois)

      total = response.dig('meta', 'total') || dois.size
      puts "    #{dois.size}/#{total} DOIs so far"

      next_url = response.dig('links', 'next')
      sleep(0.5) if next_url
    end

    dois
  end

  def parse_doi_records(response)
    (response['data'] || []).map do |doi_record|
      {
        doi: doi_record['id'],
        url: doi_record.dig('attributes', 'url'),
        state: doi_record.dig('attributes', 'state'),
        schema_version: doi_record.dig('attributes', 'schemaVersion'),
        identifiers: doi_record.dig('attributes', 'identifiers') || [],
        contributors: doi_record.dig('attributes', 'contributors') || []
      }
    end
  end

  def cross_reference(datacite_dois)
    results = {
      correct: [],
      needs_update: [],
      unexpected_url: [],
      state_mismatch: [],
      orphaned: []
    }

    datacite_dois.each do |dc_doi|
      doi_key = dc_doi[:doi].downcase
      db_entry = @db_index[doi_key]

      unless db_entry
        results[:orphaned] << dc_doi
        next
      end

      entry = { datacite: dc_doi, db: db_entry }

      if dc_doi[:state] != db_entry[:expected_state]
        results[:state_mismatch] << entry
      end

      if dc_doi[:url] == db_entry[:expected_url]
        results[:correct] << entry
      elsif catalog_url?(dc_doi[:url])
        results[:needs_update] << entry
      else
        results[:unexpected_url] << entry
      end
    end

    results
  end

  def record_public?(record)
    case record
    when Collection then !record.private?
    when Item then record.public?
    when Essence then record.item.public?
    else false
    end
  end

  def catalog_url?(url)
    return false if url.nil?

    uri = URI.parse(url)
    uri.host == 'catalog.paradisec.org.au'
  rescue URI::InvalidURIError
    false
  end

  def build_update_body(record, current_contributors: [])
    new_url = record.full_path

    attributes = {
      url: new_url,
      identifiers: [{ identifier: new_url, identifierType: 'URL' }],
      types: {
        resourceType: "PARADISEC #{record.class}",
        resourceTypeGeneral: resource_type_general(record)
      },
      schemaVersion: 'http://datacite.org/schema/kernel-4'
    }

    if current_contributors.any? { |c| c['contributorType'].blank? }
      contributors = [{ name: record.collector_name, contributorType: 'DataCollector' }]
      if record.respond_to?(:university_name) && record.university_name.present?
        contributors.push({ name: record.university_name, contributorType: 'DataCollector' })
      end
      attributes[:contributors] = contributors
    end

    { data: { type: 'dois', attributes: } }.to_json
  end

  def resource_type_general(record)
    case record
    when Item then 'Collection'
    when Essence then record.send(:essence_resource_type)
    else 'Collection'
    end
  end

  def print_report(results, dois_count)
    puts "\n#{'=' * 60}"
    puts 'DOI URL Audit Report'
    puts '=' * 60

    puts "\nDatabase DOIs: #{@db_index.size}"
    puts "DataCite DOIs in scope: #{dois_count}"

    puts "\nAudit Results:"
    puts "  Correct (URL matches): #{results[:correct].size}"
    puts "  Needs update (URL mismatch): #{results[:needs_update].size}"
    puts "  Unexpected URL (not catalog.paradisec.org.au, skipped): #{results[:unexpected_url].size}"
    puts "  State mismatch: #{results[:state_mismatch].size}"
    puts "  Orphaned (in DataCite but not in DB): #{results[:orphaned].size}"

    if results[:needs_update].any?
      puts "\nSample URLs needing update (first 10):"
      results[:needs_update].first(10).each do |entry|
        puts "  DOI: #{entry[:datacite][:doi]}"
        puts "    Type: #{entry[:db][:type]}"
        puts "    Current:  #{entry[:datacite][:url]}"
        puts "    Expected: #{entry[:db][:expected_url]}"
        puts
      end

      update_type_counts = results[:needs_update].group_by { |e| e[:db][:type] }.transform_values(&:count)
      puts '  By type:'
      %w[Collection Item Essence].each do |type|
        puts "    #{type}s: #{update_type_counts[type] || 0}"
      end
    end

    if results[:state_mismatch].any?
      puts "\nState mismatches (first 10):"
      results[:state_mismatch].first(10).each do |entry|
        puts "  DOI: #{entry[:datacite][:doi]}"
        puts "    Type: #{entry[:db][:type]}"
        puts "    DataCite state: #{entry[:datacite][:state]}"
        puts "    Expected state: #{entry[:db][:expected_state]}"
        puts
      end

      state_counts = results[:state_mismatch]
        .group_by { |e| "#{e[:datacite][:state]} -> #{e[:db][:expected_state]}" }
        .transform_values(&:count)
      puts '  By transition:'
      state_counts.each do |transition, count|
        puts "    #{transition}: #{count}"
      end
    end

    if results[:unexpected_url].any?
      puts "\nUnexpected URLs (not catalog.paradisec.org.au, first 10):"
      results[:unexpected_url].first(10).each do |entry|
        puts "  DOI: #{entry[:datacite][:doi]}"
        puts "    Current:  #{entry[:datacite][:url]}"
        puts "    Expected: #{entry[:db][:expected_url]}"
        puts
      end
    end

    if results[:orphaned].any?
      puts "\nOrphaned DOIs (first 10):"
      results[:orphaned].first(10).each do |entry|
        puts "  DOI: #{entry[:doi]} URL: #{entry[:url]}"
      end
    end

    all_entries = results[:correct] + results[:needs_update] + results[:unexpected_url]
    schema_counts = all_entries
      .group_by { |e| e[:datacite][:schema_version] || 'unknown' }
      .transform_values(&:count)
    if schema_counts.any?
      puts "\nSchema versions:"
      schema_counts.sort_by { |k, _| k }.each do |version, count|
        puts "  #{version}: #{count}"
      end
    end

    puts "\n#{'=' * 60}\n"
  end

  def update_dois(needs_update)
    return if needs_update.empty?

    puts "Updating #{needs_update.size} DOIs..."
    updated = 0
    failed = 0
    count = 0

    needs_update.each do |entry|
      doi = entry[:datacite][:doi]
      record = entry[:db][:record]
      body = build_update_body(record, current_contributors: entry[:datacite][:contributors])

      response = datacite_put("/dois/#{doi}", body)
      if response
        updated += 1
        Rails.logger.info "Updated DOI #{doi} to #{record.full_path}"
      else
        failed += 1
        Rails.logger.error "Failed to update DOI #{doi}"
      end

      count += 1
      print_progress(count)
      sleep(0.25)
    end

    print_progress_done(count)
    puts "Update complete: #{updated} updated, #{failed} failed"
  end

  def print_progress(count)
    print '.' if (count % 100).zero?
  end

  def print_progress_done(count)
    puts " (#{count})"
  end

  def timed(label)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = yield
    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(1)
    puts "#{label}: #{elapsed}s"

    result
  end

  def user_agent
    'Nabu/1.0 (https://catalog.paradisec.org.au; mailto:admin@paradisec.org.au)'
  end

  def datacite_get_url(full_url)
    uri = URI.parse(full_url)
    connection = Net::HTTP.new(uri.host, uri.port)
    connection.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Accept'] = 'application/vnd.api+json'
    request['User-Agent'] = user_agent
    request.basic_auth(@user, @pass)

    response = connection.request(request)

    unless response.code == '200'
      Rails.logger.error "DataCite GET #{full_url} failed: #{response.code} #{response.body}"

      return
    end

    JSON.parse(response.body)
  end

  def datacite_put(path, body)
    uri = URI.parse("#{@base_url}#{path}")
    connection = Net::HTTP.new(uri.host, uri.port)
    connection.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Put.new(uri.request_uri)
    request['Content-Type'] = 'application/vnd.api+json'
    request['User-Agent'] = user_agent
    request.basic_auth(@user, @pass)
    request.body = body

    response = connection.request(request)

    unless response.code == '200'
      Sentry.capture_message('DOI URL update failed', extra: { code: response.code, body: response.body, request: body })
      Rails.logger.error "DataCite PUT #{path} failed: #{response.code} #{response.body}"

      return
    end

    JSON.parse(response.body)
  end
end
