require 'csv'

module LanguageRefresh
  # Renders a Run as the report emailed to the language custodians. Built from the Run alone, so a
  # report can be sent again later.
  class Report
    INLINE_LIMIT = 20
    FACET_WARNING = 0.8

    LISTS = {
      'new' => { title: 'New', columns: %w[code name] },
      'renamed' => { title: 'Renamed', columns: %w[code old_name new_name] }
    }.freeze

    def initialize(run)
      @run = run
    end

    def subject
      counts = %w[new renamed].map { |key| "#{total(key)} #{key}" }
      "[NABU Admin] Language Refresh: 0 need a person, #{pluralize(failures.size, 'failure')}, #{counts.join(', ')}"
    end

    def body
      sections = [
        "Language Refresh Run #{@run.id}, started #{@run.started_at&.in_time_zone('Australia/Sydney')&.strftime('%F %R %Z')}",
        "Needs a person\nNothing needs a person.",
        failures_section,
        *@run.sources.map { |source, entry| source_section(source, entry) },
        in_use_section
      ]

      "#{sections.join("\n\n")}\n"
    end

    def attachments
      @run.sources.each_with_object({}) do |(source, entry), files|
        LISTS.each do |key, list|
          rows = entry.dig('changes', key) || []
          next if rows.size <= INLINE_LIMIT

          files[attachment_name(source, key)] = CSV.generate do |csv|
            csv << list[:columns]
            rows.each { |row| csv << row }
          end
        end
      end
    end

    private

    def failures
      @run.sources.filter_map do |source, entry|
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

      LISTS.each_key { |key| lines << '' << list_lines(source, key, entry.dig('changes', key) || []) }
      lines << '' << "Country links added: #{entry.dig('counts', 'country_links_added')}" if entry.dig('counts', 'country_links_added')
      lines << '' << 'Retired, Reinstated, boxes filled and Location warnings are not checked by the Refresh yet.'
      lines.join("\n")
    end

    # Every index builds the language facet from item content languages, a collection's included.
    def in_use_section
      cap = Api::V1::OniController::LANGUAGE_FACET_LIMIT
      in_use = ItemContentLanguage.distinct.count(:language_id)

      lines = ['In-use Languages', "#{in_use} of the #{cap} the language facet holds."]
      lines << "WARNING: past #{(FACET_WARNING * 100).round}% of the language facet cap" if in_use > cap * FACET_WARNING
      lines.join("\n")
    end

    def list_lines(source, key, rows)
      lines = ["#{LISTS[key][:title]}: #{rows.size}"]
      lines += rows.first(INLINE_LIMIT).map { |row| "  #{describe(source, key, row)}" }
      lines << "  and #{rows.size - INLINE_LIMIT} more in #{attachment_name(source, key)}" if rows.size > INLINE_LIMIT
      lines.join("\n")
    end

    def describe(source, key, row)
      case key
      when 'new'
        code, name = row
        Language.new(source:, code:, name:).label
      when 'renamed'
        code, old_name, new_name = row
        "#{Language.new(source:, code:, name: new_name).label}, was #{old_name}"
      end
    end

    def attachment_name(source, key)
      "#{source}-#{key}.csv"
    end

    def total(key)
      @run.sources.values.sum { |entry| entry.dig('counts', key).to_i }
    end

    def pluralize(count, word)
      "#{count} #{count == 1 ? word : word.pluralize}"
    end
  end
end
