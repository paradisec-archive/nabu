require 'csv'

module LanguageRefresh
  # Renders a Run's report. The in-use Language count is read live; everything else comes from the Run.
  class Report
    INLINE_LIMIT = 20
    FACET_WARNING = 0.8

    LISTS = {
      'new' => {
        title: 'New',
        columns: %w[code name],
        describe: ->(source, (code, name)) { Language.new(source:, code:, name:).label }
      },
      'renamed' => {
        title: 'Renamed',
        columns: %w[code old_name new_name],
        describe: ->(source, (code, old_name, new_name)) { "#{Language.new(source:, code:, name: new_name).label}, was #{old_name}" }
      }
    }.freeze

    def initialize(run)
      @run = run
    end

    def subject
      totals = LISTS.keys.map { |key| "#{@run.sources.values.sum { |entry| changes(entry, key).size }} #{key}" }
      "[NABU Admin] Language Refresh: 0 need a person, #{failures.size} #{'failure'.pluralize(failures.size)}, #{totals.join(', ')}"
    end

    def body
      [
        "Language Refresh Run #{@run.id}, started #{@run.started_at&.in_time_zone('Australia/Sydney')&.strftime('%F %R %Z')}",
        "Needs a person\nNothing needs a person.",
        failures_section,
        *@run.sources.map { |source, entry| source_section(source, entry) },
        in_use_section
      ].join("\n\n")
    end

    def attachments
      @run.sources.each_with_object({}) do |(source, entry), files|
        LISTS.each do |key, list|
          rows = changes(entry, key)
          next if rows.size <= INLINE_LIMIT

          files[attachment_name(source, key)] = CSV.generate do |csv|
            csv << list[:columns]
            rows.each { |row| csv << row }
          end
        end
      end
    end

    private

    def changes(entry, key)
      entry.dig('changes', key) || []
    end

    def failures
      @failures ||= @run.sources.filter_map do |source, entry|
        "#{Language::SOURCE_NAMES[source]} #{entry['status']}: #{entry['error']}" if %w[failed refused].include?(entry['status'])
      end
    end

    def failures_section
      "Failures\n#{failures.any? ? failures.join("\n") : 'None.'}"
    end

    def source_section(source, entry)
      lines = [Language::SOURCE_NAMES[source], "Status: #{entry['status']}"]
      lines << "Versions: #{entry['version'].map { |file, version| "#{file} #{version}" }.join(', ')}" if entry['version']
      lines << "Rows read: #{entry['rows']}" if entry['rows']
      return lines.join("\n") unless entry['status'] == 'applied'

      LISTS.each_key { |key| lines << '' << list_lines(source, key, changes(entry, key)) }
      entry.fetch('counts', {}).each { |key, count| lines << '' << "#{key.humanize}: #{count}" }
      lines << '' << 'Retired, Reinstated, Bounding boxes filled and Location warnings are not checked by the Refresh yet.'
      lines.join("\n")
    end

    # Every index builds the language facet from item content languages, a collection's included.
    def in_use_section
      cap = Oni::SearchCapabilities::LANGUAGE_FACET_LIMIT
      in_use = ItemContentLanguage.distinct.count(:language_id)

      lines = ['In-use Languages', "#{in_use} of the #{cap} the language facet holds."]
      lines << "WARNING: past #{(FACET_WARNING * 100).round}% of the language facet cap" if in_use > cap * FACET_WARNING
      lines.join("\n")
    end

    def list_lines(source, key, rows)
      lines = ["#{LISTS[key][:title]}: #{rows.size}"]
      lines += rows.first(INLINE_LIMIT).map { |row| "  #{LISTS[key][:describe].call(source, row)}" }
      lines << "  and #{rows.size - INLINE_LIMIT} more in #{attachment_name(source, key)}" if rows.size > INLINE_LIMIT
      lines.join("\n")
    end

    def attachment_name(source, key)
      "#{source}-#{key}.csv"
    end
  end
end
