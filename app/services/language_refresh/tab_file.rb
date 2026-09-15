module LanguageRefresh
  # A tab-separated table whose header must name the columns a stage reads, so an error page served
  # in place of the table fails the stage instead of reading as an empty Source.
  class TabFile
    attr_reader :rows, :version

    def self.parse(response, required_columns)
      new(File.basename(URI(response.url).path), response.body, response.version, required_columns)
    end

    def initialize(name, body, version, required_columns)
      header, *lines = body.split(/\r?\n/).reject(&:blank?)
      columns = header.to_s.split("\t")
      missing = required_columns - columns
      raise Fetcher::FetchError, "#{name} is missing columns #{missing.join(', ')}" if missing.any?

      @version = version
      @rows = lines.map { |line| columns.zip(line.split("\t", -1)).to_h }
    end
  end
end
