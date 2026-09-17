require 'json'

module LanguageRefresh
  # A table CKAN's datastore answers with, guarded the same way TabFile and CsvFile are: a refusal,
  # a page short of the rows it counted, or a table without the columns a stage reads fails the
  # stage instead of reading as a Source that has emptied.
  class DatastoreTable
    attr_reader :rows, :version

    def initialize(response, required_columns)
      result = successful_result(response)

      missing = required_columns - result.fetch('fields', []).pluck('id')
      raise Fetcher::FetchError, "#{name_of(response)} is missing columns #{missing.join(', ')}" if missing.any?

      @rows = result.fetch('records', [])
      raise Fetcher::FetchError, "#{name_of(response)} answered #{@rows.size} of #{result['total']} rows" if @rows.size < result['total'].to_i

      @version = response.version
    end

    private

    def successful_result(response)
      payload = JSON.parse(response.body)
      return payload.fetch('result', {}) if payload['success']

      raise Fetcher::FetchError, "#{name_of(response)} refused the request: #{payload.dig('error', 'message') || 'no reason given'}"
    rescue JSON::ParserError => e
      raise Fetcher::FetchError, "#{name_of(response)} did not answer with JSON: #{e.message}"
    end

    def name_of(response)
      File.basename(URI(response.url).path)
    end
  end
end
