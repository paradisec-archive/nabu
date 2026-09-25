module LanguageRefresh
  # A tab-separated table whose header must name the columns a stage reads, so an error page served
  # in place of the table fails the stage instead of reading as an empty Source.
  class TabFile
    attr_reader :rows, :version

    def initialize(response, required_columns)
      header, *lines = response.body.split(/\r?\n/).reject(&:blank?)
      columns = header.to_s.split("\t")
      missing = required_columns - columns
      raise Fetcher::FetchError, "#{response.name} is missing columns #{missing.join(', ')}" if missing.any?

      @version = response.version
      @rows = lines.map { |line| columns.zip(line.split("\t", -1)).to_h }
    end
  end
end
