require 'csv'

module LanguageRefresh
  # Renders a Run's report. The in-use Language count and everything under "Needs a person" are read
  # live from the database; the rest comes from the Run.
  class Report
    INLINE_LIMIT = 20
    FACET_WARNING = 0.8
    HELD_ATTACHMENT = 'needs-a-person.csv'.freeze

    TAG_TABLES = [CollectionLanguage, ItemContentLanguage, ItemSubjectLanguage].freeze

    # A row carries its own column names, so the same row renders as a Label in the body and as a
    # line in the CSV, and a Source can add a column without disturbing the others.
    LISTS = {
      'new' => { title: 'New', columns: %w[code name] },
      'renamed' => {
        title: 'Renamed',
        columns: %w[code old_name name],
        describe: ->(row, label) { "#{label}, was #{row['old_name']}" }
      },
      'dialect_changed' => { title: 'Dialect flag changed', columns: %w[code name dialect] },
      'retired_rewritten' => {
        title: 'Retired and rewritten',
        columns: %w[code name change_to moved],
        describe: ->(row, label) { "#{label} → #{row['change_to']}, #{row['moved']} #{'tag'.pluralize(row['moved'])} moved" }
      },
      'retired_held' => { title: 'Retired and held', columns: %w[code name] },
      'reinstated' => { title: 'Reinstated', columns: %w[code name] },
      'boxes_filled' => { title: 'Bounding boxes filled from the Source point', columns: %w[code name] }
    }.freeze

    def initialize(run)
      @run = run
    end

    def subject
      counts = [
        "#{held.size} need a person",
        "#{failures.size} #{'failure'.pluralize(failures.size)}",
        "#{total('new')} new",
        "#{total('renamed')} renamed",
        "#{total('retired_rewritten') + total('retired_held')} retired",
        "#{total('reinstated')} reinstated"
      ]
      "[NABU Admin] Language Refresh: #{counts.join(', ')}"
    end

    def body
      [
        "Language Refresh Run #{@run.id}, started #{@run.started_at&.in_time_zone('Australia/Sydney')&.strftime('%F %R %Z')}",
        needs_a_person_section,
        failures_section,
        *@run.sources.map { |source, entry| source_section(source, entry) },
        in_use_section
      ].join("\n\n")
    end

    def attachments
      files = @run.sources.each_with_object({}) do |(source, entry), collected|
        LISTS.each do |key, list|
          rows = changes(entry, key)
          next if rows.size <= INLINE_LIMIT

          collected[attachment_name(source, key)] = csv(list[:columns], rows)
        end
      end

      files[HELD_ATTACHMENT] = held_csv if held.any? { |entry| links_for(entry).size > INLINE_LIMIT }
      files
    end

    private

    def changes(entry, key)
      entry.dig('changes', key) || []
    end

    def total(key)
      @run.sources.values.sum { |entry| changes(entry, key).size }
    end

    def failures
      @failures ||= @run.sources.filter_map do |source, entry|
        "#{Language::SOURCE_NAMES[source]} #{entry['status']}: #{entry['error']}" if %w[failed refused].include?(entry['status'])
      end
    end

    def failures_section
      "Failures\n#{failures.any? ? failures.join("\n") : 'None.'}"
    end

    # Every Retired Language still tagged, whichever Run retired it, so nothing waits in a queue.
    def held
      @held ||= @run.sources.values.flat_map { |entry| entry['held'] || [] }
    end

    def needs_a_person_section
      return "Needs a person\nNothing needs a person." if held.empty?

      ['Needs a person', *held.map { |entry| held_lines(entry) }].join("\n")
    end

    def held_lines(entry)
      language = languages[entry['language_id']]
      links = links_for(entry)

      lines = [language.label, "  Retired: #{entry['reason'] || 'no longer published'}"]
      lines << "  Remedy: #{entry['remedy']}" if entry['remedy'].present?
      lines << "  Tagged: #{tag_counts(language).join(', ')}"
      lines += links.first(INLINE_LIMIT).map { |identifier, url| "  #{identifier}: #{url}" }
      lines << "  and #{links.size - INLINE_LIMIT} more in #{HELD_ATTACHMENT}" if links.size > INLINE_LIMIT
      lines.join("\n")
    end

    def languages
      @languages ||= Language.where(id: held.map { |entry| entry['language_id'] }).index_by(&:id)
    end

    def tag_counts(language)
      TAG_TABLES.filter_map do |model|
        count = model.where(language_id: language.id).count
        "#{model.table_name} #{count}" if count.positive?
      end
    end

    def links_for(entry)
      @links_for ||= {}
      @links_for[entry['language_id']] ||= edit_links(languages[entry['language_id']])
    end

    def edit_links(language)
      collections = Collection.where(id: CollectionLanguage.where(language_id: language.id).select(:collection_id))
      items = Item.where(id: ItemContentLanguage.where(language_id: language.id).select(:item_id))
                  .or(Item.where(id: ItemSubjectLanguage.where(language_id: language.id).select(:item_id)))

      collections.order(:identifier).map { |collection| [collection.identifier, url_helpers.edit_collection_url(collection, **url_options)] } +
        items.includes(:collection).order(:collection_id, :identifier).map do |item|
          [item.full_identifier, url_helpers.edit_collection_item_url(item.collection, item, **url_options)]
        end
    end

    def url_helpers
      Rails.application.routes.url_helpers
    end

    def url_options
      host = Rails.application.config.action_mailer.default_url_options&.dig(:host) || 'catalog.paradisec.org.au'
      { host:, protocol: 'https' }
    end

    def held_csv
      CSV.generate do |csv|
        csv << %w[source code name reason remedy record url]
        held.each do |entry|
          language = languages[entry['language_id']]
          links_for(entry).each do |identifier, url|
            csv << [language.source, language.code, language.name, entry['reason'], entry['remedy'], identifier, url]
          end
        end
      end
    end

    def source_section(source, entry)
      lines = [Language::SOURCE_NAMES[source], "Status: #{entry['status']}"]
      lines << "Versions: #{entry['version'].map { |file, version| "#{file} #{version}" }.join(', ')}" if entry['version']
      lines << "Rows read: #{entry['rows']}" if entry['rows']
      return lines.join("\n") unless entry['status'] == 'applied'

      LISTS.each_key { |key| lines << '' << list_lines(source, key, changes(entry, key)) if entry.dig('changes', key) }
      entry.fetch('counts', {}).each { |key, count| lines << '' << "#{key.humanize}: #{count}" }
      lines << '' << 'Location warnings are not checked by the Refresh yet.'
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
      lines += rows.first(INLINE_LIMIT).map { |row| "  #{describe(source, key, row)}" }
      lines << "  and #{rows.size - INLINE_LIMIT} more in #{attachment_name(source, key)}" if rows.size > INLINE_LIMIT
      lines.join("\n")
    end

    def describe(source, key, row)
      label = Language.new(source:, code: row['code'], name: row['name'], dialect: row['dialect'] || false).label
      LISTS[key][:describe]&.call(row, label) || label
    end

    def csv(columns, rows)
      CSV.generate do |file|
        file << columns
        rows.each { |row| file << columns.map { |column| row[column] } }
      end
    end

    def attachment_name(source, key)
      "#{source}-#{key}.csv"
    end
  end
end
