# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength Rails/Output
namespace :import do
  desc 'Import ethnologue'
  task ethnologue: %i[countries languages countries_languages retired]

  desc 'Import countries from ethnologue'
  task countries: :environment do
    puts '# Importing countries from Ethnologue'
    puts

    Nabu::LanguageSources.new.countries.each do |code, name, _area|
      country = Country.find_by(code:)
      unless country
        Country.create!(name:, code:)
        puts "Added #{code} - #{name}"

        next
      end

      next if country.name == name

      country.name = name
      country.save!
      puts "Updated #{code} - #{country.name_before_last_save} -> #{name}"
    end
  end

  desc 'Import languages from ethnologue'
  task languages: :environment do
    puts '# Importing languages from Ethnologue'
    puts

    Nabu::LanguageSources.new.languages.each do |code, _country_code, status, name|
      next unless status == 'L'

      name = name.gsub(/ \(.*\)/, '')

      language = Language.find_by(code:)
      unless language
        Language.create!(code:, name:)
        puts "Added #{code} - #{name}"

        next
      end

      next if language.retired
      next if language.name == name

      language.name = name
      language.save!
      puts "Updated #{code} - #{language.name_before_last_save} -> #{name}"
    end
  end

  desc 'Import country languages from ethnologue'
  task countries_languages: :environment do
    puts '# Importing country languages from Ethnologue'
    puts

    sources = Nabu::LanguageSources.new
    extinct = Set.new

    sources.language_index.each do |language_code, country_code, status, _name|
      next unless status == 'L'

      language = Language.find_by(code: language_code)
      unless language
        if sources.language_status[language_code] == 'X'
          extinct << language_code
        else
          puts "ERROR: Language not in DB #{language_code} - skipping"
        end
        next
      end

      country = Country.find_by(code: country_code)
      unless country
        puts "ERROR: Country not in DB #{country_code} - skipping"
        next
      end

      next if CountriesLanguage.exists?(country_id: country.id, language_id: language.id)

      CountriesLanguage.create!(country:, language:)
      puts "Added mapping #{language.code} -> #{country.code}"
    end

    puts "Skipped #{extinct.size} extinct languages not in DB: #{extinct.sort.join(' ')}" if extinct.any?
  end

  desc 'Update retired language codes from SIL'
  task retired: :environment do
    puts '# Importing retired languages'
    puts

    sources = Nabu::LanguageSources.new
    puts "Using #{sources.iso639_zip_url}"
    puts

    models = [CollectionLanguage, ItemContentLanguage, ItemSubjectLanguage]
    retired = 0

    sources.retirements.each do |code, name, reason, change_to, instructions, effective|
      language = Language.find_by(code:)
      next unless language
      next if language.retired

      language.retired = true
      language.name = "#{language.name} (retired)"
      language.save!
      retired += 1
      puts "Retired #{code} - #{name} effective #{effective}"

      counts = models.to_h { |model| [model, model.where(language_id: language.id).count] }
      in_use = counts.values.sum.positive?

      # C=change, D=duplicate, M=merge have a single replacement code so existing entries can be moved automatically
      if %w[C D M].include?(reason) && change_to.present?
        new_language = Language.find_by(code: change_to)

        if new_language.nil? && in_use
          new_name = sources.iso639_names[change_to]
          if new_name
            new_language = Language.create!(code: change_to, name: new_name)
            puts "Added #{change_to} - #{new_name}"
          else
            puts "New Language #{change_to} not found - not updating DB entries"
          end
        end

        models.each { |model| Nabu::LanguageReassigner.new(model).reassign(language, new_language) } if new_language
      elsif in_use
        puts "INSTRUCTIONS: #{instructions.presence || 'No replacement code, reassign manually'}"
        counts.each do |model, count|
          puts "Edit #{count} records in #{model.table_name}" if count.positive?
        end
        Nabu::LanguageReviewLinks.new(language).each { |line| puts line }
      end

      puts '---'
    end

    puts 'None' if retired.zero?
  end
end
# rubocop:enable Metrics/BlockLength Rails/Output
