require 'csv'

module LanguageRefresh
  # A CSV table whose header must name the columns a stage reads, so an error page served in place
  # of the table fails the stage instead of reading as an empty Source.
  class CsvFile
    attr_reader :rows, :version

    def initialize(response, required_columns)
      table = parse(response)
      missing = required_columns - table.headers.compact
      raise Fetcher::FetchError, "#{name_of(response)} is missing columns #{missing.join(', ')}" if missing.any?

      @version = response.version
      @rows = table.map(&:to_h)
    end

    private

    def parse(response)
      CSV.parse(response.body, headers: true)
    rescue CSV::MalformedCSVError => e
      raise Fetcher::FetchError, "#{name_of(response)} is not a CSV table: #{e.message}"
    end

    def name_of(response)
      File.basename(URI(response.url).path)
    end
  end
end
