# frozen_string_literal: true

require 'curb'
require 'zip'

def fetch(url)
  curl = Curl.get(url) do |http|
    http.follow_location = true
    http.enable_cookies = true
    http.max_redirects = 3
    http.encoding = 'UTF-8'
    # http.verbose = true
  end

  curl.body_str.force_encoding('UTF-8')
end

# rubocop:disable Metrics/BlockLength Rails/Output
namespace :import do
  desc 'Import ethnologue'
  task ethnologue: %i[countries languages countries_languages retired]

  desc 'Import countries from ethnologue'
  task countries: :environment do
    puts '# Importing countries from Ethnologue'
    puts

    data = fetch('https://www.ethnologue.com/codes/CountryCodes.tab')

    data.each_line do |line|
      next if line =~ /CountryID/

      code, name, _area = line.split("\t")

      country = Country.find_by(code:)
      unless country
        country = Country.create(name:, code:)
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

    data = fetch('https://www.ethnologue.com/codes/LanguageCodes.tab')

    data.each_line do |line|
      next if line =~ /LangID/

      code, _country_code, status, name = line.strip.split("\t")
      next unless status == 'L'

      name = name.gsub(/ \(.*\)/, '')

      language = Language.find_by(code:)
      unless language
        language = Language.create(code:, name:)
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

    data = fetch('https://www.ethnologue.com/codes/LanguageIndex.tab')

    data.each_line do |line|
      next if line =~ /LangID/

      language_code, country_code, status, _name = line.strip.split("\t")
      next unless status == 'L'

      language = Language.find_by(code: language_code)
      unless language
        puts "ERROR: Language not in DB #{language_code} - skipping"
        next
      end

      country = Country.find_by(code: country_code)
      unless country
        puts "ERROR: Country not in DB #{country_code} - skipping"
        next
      end

      lang_country = CountriesLanguage.find_by(country_id: country.id, language_id: language.id)
      next if lang_country

      CountriesLanguage.create(country:, language:)
      puts "Added mapping #{language.code} -> #{country.code}"
    end
  end

  desc 'Update retired language codes from SIL'
  task retired: :environment do
    puts '# Importing retired languages'
    puts

    zip = Curl.get('https://iso639-3.sil.org/sites/iso639-3/files/downloads/iso-639-3_Code_Tables_20230123.zip').body_str

    data = ''
    Zip::File.open_buffer(zip) do |zip_file|
      zip_file.each do |entry|
        data = entry.get_input_stream.read if entry.name =~ /iso-639-3_Retirements_20230123.tab/
      end
    end

    data.each_line do |line|
      next if line =~ /Ref_Name/

      code, name, reason, change_to, instructions, effective = line.strip.split("\t")

      # find language and set to retired if it's not already retired
      language = Language.find_by(code:)
      next unless language

      next if language.retired

      language.retired = true
      language.name = "#{language.name} (retired)"
      language.save!
      puts "Retired #{code} - #{name} effective #{effective}"

      # if change reason is C=change, D=duplicate, M=merge, fix existing entries
      if %w[C D M].include?(reason) && change_to
        new_lang = Language.find_by(code: change_to)
        unless new_lang
          puts "New Language #{change_to} not found - not updating DB entries"
          puts '---'
          next
        end

        # rubocop:disable Rails/SkipsModelValidations
        begin
          num = CollectionLanguage.where(language_id: language.id).update_all(language_id: new_lang.id)
        rescue Mysql2::Error
          # Ignore
        end
        puts "Updated #{num} collection_languages" if num.positive?

        begin
          num = ItemContentLanguage.where(language_id: language.id).update_all(language_id: new_lang.id)
        rescue Mysql2::Error
          # Ignore
        end
        puts "Updated #{num} item_content_languages" if num.positive?

        begin
          num = ItemSubjectLanguage.where(language_id: language.id).update_all(language_id: new_lang.id)
        rescue Mysql2::Error
          # Ignore
        end
        puts "Updated #{num} item_subject_languages" if num.positive?
        # rubocop:enable Rails/SkipsModelValidations
      else
        num_a = CollectionLanguage.where(language_id: language.id).count
        num_b = ItemContentLanguage.where(language_id: language.id).count
        num_c = ItemSubjectLanguage.where(language_id: language.id).count

        puts "INSTRUCTIONS: #{instructions}" if num_a.positive? || num_b.positive? || num_c.positive?

        puts "Edit #{num} records in collection_languages" if num_a.positive?
        puts "Edit #{num} records in item_content_languages" if num_b.positive?
        puts "Edit #{num} records in item_subject_languages" if num_c.positive?
      end

      puts '---'
    end
  end
end
# rubocop:enable Metrics/BlockLength Rails/Output
