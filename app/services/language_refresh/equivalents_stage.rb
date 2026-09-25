module LanguageRefresh
  # Regenerates the advisory Equivalents in full, so a pair whose evidence has gone is simply not
  # written again. Seeds are Glottolog's own ISO columns, Chirila's curated codes and names two
  # Sources publish alike; a seed naming a Code no Language holds is not taken. Names come from the
  # Languages the Source stages have just brought into line, which is what their files say.
  class EquivalentsStage
    CHIRILA_FILE = Rails.root.join('vendor/data/chirila-codes.csv')
    CHIRILA_COLUMNS = %w[austlang_code iso639_3 glottocode].freeze
    # A fixed deposit vendored in the repo, so the file is its own version.
    CHIRILA_VERSION = 'Bowern 2021, doi:10.5281/zenodo.4898185'.freeze

    INSERT_BATCH = 1_000

    # Glottolog's table is read here as well as in its own stage: its ISO columns are a seed, and
    # nothing about them is kept on a Language. A Run downloads it once for both. A failed read fails
    # this stage too, which leaves the Equivalents of the Run before rather than regenerating them
    # without those pairs.
    def initialize(fetcher)
      @glottolog = GlottologStage.new(fetcher)
    end

    # Equivalents are not a Source; this names the stage in the Run and the report.
    def source
      'equivalents'
    end

    def fetch
      @chirila = CsvFile.new(chirila_response, CHIRILA_COLUMNS).rows
      @glottolog.fetch
    end

    def version
      { 'chirila-codes.csv' => CHIRILA_VERSION, **@glottolog.version }
    end

    def row_count
      @chirila.size
    end

    def apply(_run)
      index_languages
      @pairs = Hash.new { |pairs, key| pairs[key] = [] }

      seed_from_glottolog
      seed_from_chirila
      seed_from_names

      { counts: { pairs: write, **evidence_counts } }
    end

    private

    def chirila_response
      Fetcher::Response.new(url: CHIRILA_FILE.to_s, body: CHIRILA_FILE.read, version: CHIRILA_VERSION)
    end

    # Every Language, by Code within its Source for the Code seeds and by normalised name and
    # Source for the name seed.
    def index_languages
      @codes = Hash.new { |sources, source| sources[source] = {} }
      @names = Hash.new { |names, name| names[name] = Hash.new { |sources, source| sources[source] = [] } }

      Language.pluck(:id, :source, :code, :name).each do |id, source, code, name|
        @codes[source][code] = id
        normalised = normalise(name)
        @names[normalised][source] << id if normalised.present?
      end
    end

    def language_id(source, code)
      @codes[source][code.to_s] if code.present?
    end

    def pair(one_id, other_id, tag)
      return if one_id.nil? || other_id.nil? || one_id == other_id

      @pairs[LanguageEquivalent.ordered_pair(one_id, other_id)] |= [tag]
    end

    # Glottolog names the ISO code for a Language it takes to be the same, and the closest ISO code
    # for one it does not. The two agree wherever a row has a code of its own, so only a closest
    # code that differs says anything the ISO column has not already said.
    def seed_from_glottolog
      @glottolog.iso_codes.each do |code, iso, closest|
        glottolog = language_id('glottolog', code)

        pair(glottolog, language_id('iso639_3', iso), 'glottolog:iso')
        pair(glottolog, language_id('iso639_3', closest), 'glottolog:closest_iso') if closest && closest != iso
      end
    end

    def seed_from_chirila
      @chirila.each do |row|
        austlang = language_id('austlang', row['austlang_code'])

        pair(austlang, language_id('iso639_3', row['iso639_3']), 'chirila:iso')
        pair(austlang, language_id('glottolog', row['glottocode']), 'chirila:glottocode')
      end
    end

    # One Source publishing the same name twice says nothing, so only Languages across two Sources
    # are crossed.
    def seed_from_names
      @names.each_value do |by_source|
        by_source.values.combination(2) { |ones, others| ones.product(others).each { |one, other| pair(one, other, 'name') } }
      end
    end

    # Enough to see through the spelling each Source happens to use: accents, case, punctuation and
    # a parenthesised qualifier.
    def normalise(name)
      name.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '').gsub(/\(.*?\)|\[.*?\]/, ' ').downcase.gsub(/[^a-z0-9]/, '')
    end

    def write
      LanguageEquivalent.delete_all
      rows = @pairs.map do |(language_id, related_language_id), evidence|
        { language_id:, related_language_id:, evidence: LanguageEquivalent.sort_evidence(evidence) }
      end
      rows.each_slice(INSERT_BATCH) { |batch| LanguageEquivalent.insert_all(batch) }
      rows.size
    end

    # One count per evidence tag, so a seed that has stopped producing pairs shows in the report.
    def evidence_counts
      tally = Hash.new(0)
      @pairs.each_value { |evidence| evidence.each { |tag| tally[tag] += 1 } }
      LanguageEquivalent::EVIDENCE.keys.to_h { |tag| [tag.tr(':', '_'), tally[tag]] }
    end
  end
end
