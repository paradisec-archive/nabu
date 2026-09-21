require 'csv'

module LanguageRefresh
  # Renders a Run's report. The in-use Language count and everything under "Needs a person" are read
  # live from the database; the rest comes from the Run. The text body and the mailer's HTML part both
  # render the same section data, so the two cannot drift.
  class Report
    INLINE_LIMIT = 20
    FACET_WARNING = 0.8
    HELD_ATTACHMENT = 'needs-a-person.csv'.freeze

    # What each stage is called in the report. Every stage but the Equivalents one is a Source.
    STAGE_NAMES = Language.source_names.merge('equivalents' => 'Equivalents').freeze

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
      'boxes_filled' => { title: 'Bounding boxes filled from the Source point', columns: %w[code name] },
      'location_warnings' => {
        title: 'Location warnings',
        columns: %w[code name distance_km],
        describe: ->(row, label) { "#{label}, the Source point is #{row['distance_km']} km outside the Bounding box" }
      }
    }.freeze

    Held = Data.define(:language, :reason, :remedy, :tags, :links) do
      def retired_because = reason || 'no longer published'
      def shown_links = links.first(INLINE_LIMIT)
      def more = [links.size - INLINE_LIMIT, 0].max
      def attachment = HELD_ATTACHMENT
    end

    # A row reads as its Label plus whichever columns the Label does not already say.
    Listing = Data.define(:source, :key, :rows) do
      def title = LISTS.fetch(key)[:title]
      def columns = LISTS.fetch(key)[:columns]
      def shown = rows.first(INLINE_LIMIT)
      def more = [rows.size - INLINE_LIMIT, 0].max
      def attachment = "#{source}-#{key}.csv"
      def headers = ['Language', *extra_columns.map(&:humanize)]
      def cells(row) = [label(row), *extra_columns.map { |column| row[column] }]
      def line(row) = LISTS.fetch(key)[:describe]&.call(row, label(row)) || label(row)

      private

      def extra_columns = columns - %w[code name dialect]

      def label(row)
        Language.new(source:, code: row['code'], name: row['name'], dialect: row['dialect'] || false).label
      end
    end

    SourceSummary = Data.define(:name, :status, :versions, :rows_read, :lists, :counts) do
      def applied? = status == 'applied'
      def totals = lists.to_h { |listing| [listing.title, listing.rows.size] }.merge(counts.to_h)
    end

    # Every index builds the language facet from item content languages, a collection's included.
    InUse = Data.define(:count, :cap) do
      def warning? = count > cap * FACET_WARNING
      def warning = "past #{(FACET_WARNING * 100).round}% of the language facet cap"
    end

    attr_reader :run

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

    def started_at
      @run.started_at&.in_time_zone('Australia/Sydney')&.strftime('%F %R %Z')
    end

    def body
      [
        "Language Refresh Run #{@run.id}, started #{started_at}",
        needs_a_person_text,
        "Failures\n#{failures.any? ? failures.join("\n") : 'None.'}",
        *sources.map { |source| source_text(source) },
        in_use_text
      ].join("\n\n")
    end

    def attachments
      files = sources.flat_map(&:lists).each_with_object({}) do |listing, collected|
        collected[listing.attachment] = csv(listing.columns, listing.rows) if listing.more.positive?
      end

      files[HELD_ATTACHMENT] = held_csv if held.any? { |entry| entry.more.positive? }
      files
    end

    def failures
      @failures ||= @run.sources.filter_map do |source, entry|
        "#{STAGE_NAMES.fetch(source)} #{entry['status']}: #{entry['error']}" if %w[failed refused].include?(entry['status'])
      end
    end

    # Every Retired Language still tagged, whichever Run retired it, read from the database rather
    # than from the stages, so a Source that failed its fetch shortens nothing. A stage that did run
    # says why its own Languages were retired and what to do about them.
    def held
      @held ||= held_languages.map do |language|
        reason = reasons.fetch(language.id, {})
        Held.new(language:, reason: reason['reason'], remedy: reason['remedy'].presence, tags: tag_counts(language), links: edit_links(language))
      end
    end

    def sources
      @sources ||= @run.sources.map do |source, entry|
        applied = entry['status'] == 'applied'
        lists = LISTS.keys.filter_map { |key| Listing.new(source:, key:, rows: entry.dig('changes', key)) if entry.dig('changes', key) }
        counts = entry.fetch('counts', {}).map { |key, count| [key.humanize, count] }

        SourceSummary.new(
          name: STAGE_NAMES.fetch(source), status: entry['status'], versions: entry['version'], rows_read: entry['rows'],
          lists: applied ? lists : [], counts: applied ? counts : []
        )
      end
    end

    def in_use
      @in_use ||= InUse.new(count: ItemContentLanguage.distinct.count(:language_id), cap: Oni::SearchCapabilities::LANGUAGE_FACET_LIMIT)
    end

    private

    def changes(entry, key)
      entry.dig('changes', key) || []
    end

    def total(key)
      @run.sources.values.sum { |entry| changes(entry, key).size }
    end

    def held_languages
      Language.where(retired: true).tagged.in_order_of(:source, Language.source_names.keys).order(:code)
    end

    def reasons
      @reasons ||= @run.sources.values.flat_map { |entry| entry['held'] || [] }.index_by { |entry| entry['language_id'] }
    end

    def tag_counts(language)
      Language::TAGGINGS.filter_map do |model|
        count = model.where(language_id: language.id).count
        "#{model.table_name} #{count}" if count.positive?
      end
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
      { host: Rails.application.config.action_mailer.default_url_options.fetch(:host), protocol: 'https' }
    end

    def held_csv
      CSV.generate do |csv|
        csv << %w[source code name reason remedy record url]
        held.each do |entry|
          language = entry.language
          entry.links.each do |identifier, url|
            csv << [language.source, language.code, language.name, entry.reason, entry.remedy, identifier, url]
          end
        end
      end
    end

    def csv(columns, rows)
      CSV.generate do |file|
        file << columns
        rows.each { |row| file << columns.map { |column| row[column] } }
      end
    end

    def needs_a_person_text
      return "Needs a person\nNothing needs a person." if held.empty?

      ['Needs a person', *held.map { |entry| held_text(entry) }].join("\n")
    end

    def held_text(entry)
      lines = [entry.language.label, "  Retired: #{entry.retired_because}"]
      lines << "  Remedy: #{entry.remedy}" if entry.remedy
      lines << "  Tagged: #{entry.tags.join(', ')}"
      lines += entry.shown_links.map { |identifier, url| "  #{identifier}: #{url}" }
      lines << "  and #{entry.more} more in #{entry.attachment}" if entry.more.positive?
      lines.join("\n")
    end

    def source_text(source)
      lines = [source.name, "Status: #{source.status}"]
      lines << "Versions: #{source.versions.map { |file, version| "#{file} #{version}" }.join(', ')}" if source.versions
      lines << "Rows read: #{source.rows_read}" if source.rows_read
      source.lists.each { |listing| lines << '' << list_text(listing) }
      lines << '' << source.counts.map { |name, count| "#{name}: #{count}" }.join("\n") if source.counts.any?
      lines.join("\n")
    end

    def list_text(listing)
      lines = ["#{listing.title}: #{listing.rows.size}"]
      lines += listing.shown.map { |row| "  #{listing.line(row)}" }
      lines << "  and #{listing.more} more in #{listing.attachment}" if listing.more.positive?
      lines.join("\n")
    end

    def in_use_text
      lines = ['In-use Languages', "#{in_use.count} of the #{in_use.cap} the language facet holds."]
      lines << "WARNING: #{in_use.warning}" if in_use.warning?
      lines.join("\n")
    end
  end
end
