require 'rails_helper'

# ## Schema Information
#
# Table name: `languages`
# Database name: `primary`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`id`**           | `integer`          | `not null, primary key`
# **`code`**         | `string(255)`      |
# **`dialect`**      | `boolean`          | `default(FALSE), not null`
# **`east_limit`**   | `float(24)`        |
# **`name`**         | `string(255)`      |
# **`north_limit`**  | `float(24)`        |
# **`retired`**      | `boolean`          | `default(FALSE), not null`
# **`source`**       | `string(255)`      | `not null`
# **`south_limit`**  | `float(24)`        |
# **`west_limit`**   | `float(24)`        |
#
# ### Indexes
#
# * `index_languages_on_code_and_source` (_unique_):
#     * **`code`**
#     * **`source`**
#
describe Language, type: :model do
  it 'rejects a swapped map extent (east < west with a positive east edge)' do
    language = build(:language, west_limit: 154.64, east_limit: 140.8, north_limit: -1.59, south_limit: -12.35)

    expect(language).not_to be_valid
    expect(language.errors[:east_limit]).to be_present
  end

  it 'allows a map extent crossing the antimeridian' do
    language = build(:language, west_limit: 170.0, east_limit: -170.0, north_limit: -1.5, south_limit: -12.25)

    expect(language).to be_valid
  end

  describe 'codes and sources' do
    it 'saves one language per code from each source' do
      expect(build(:language, source: :iso639_3, code: 'wbp')).to be_valid
      expect(build(:language, source: :glottolog, code: 'warl1254')).to be_valid
      expect(build(:language, source: :austlang, code: 'C15')).to be_valid
    end

    it 'saves the austlang codes that carry a suffix' do
      expect(build(:language, source: :austlang, code: 'A38.1')).to be_valid
      expect(build(:language, source: :austlang, code: 'N116.A')).to be_valid
    end

    it 'saves a glottocode whose first four characters include a numeral' do
      expect(build(:language, source: :glottolog, code: '17th1234')).to be_valid
    end

    it 'rejects a code that is not shaped like its source publishes' do
      expect(build(:language, source: :iso639_3, code: 'warl1254')).not_to be_valid
      expect(build(:language, source: :iso639_3, code: 'wb')).not_to be_valid
      expect(build(:language, source: :glottolog, code: 'wbp')).not_to be_valid
      expect(build(:language, source: :glottolog, code: 'warl125')).not_to be_valid
      expect(build(:language, source: :austlang, code: 'wbp')).not_to be_valid
      expect(build(:language, source: :austlang, code: '15')).not_to be_valid
    end

    it 'names the source in the error on a malformed code' do
      language = build(:language, source: :glottolog, code: 'wbp')
      language.validate

      expect(language.errors[:code].join).to include('Glottolog')
    end

    it 'requires a source' do
      expect(build(:language, source: nil)).not_to be_valid
    end

    it 'rejects a source no registry supplies' do
      language = build(:language)
      language.source = 'linguameta'

      expect(language).not_to be_valid
      expect(language.errors[:source]).to be_present
    end

    it 'rejects a second row with the same code in the same source' do
      create(:language, source: :iso639_3, code: 'wbp')

      expect(build(:language, source: :iso639_3, code: 'wbp')).not_to be_valid
    end

    it 'rejects a code that differs only in case within one source' do
      create(:language, source: :austlang, code: 'C15')
      language = build(:language, source: :austlang, code: 'c15')
      language.validate

      expect(language.errors.details[:code]).to include(a_hash_including(error: :taken))
    end

    # No code is well formed for two sources at once, so the only way to see that uniqueness
    # moved from the code to the pair is to write past the validations to the index itself.
    it 'keys uniqueness on the code and its source rather than the code alone' do
      create(:language, source: :iso639_3, code: 'wbp')
      row = { code: 'wbp', source: 'glottolog', name: 'Not a real glottolog row', dialect: false, retired: false }

      expect { described_class.insert_all!([row]) }.to change(described_class, :count).by(1)
    end
  end

  describe '#label' do
    it 'reads name, code and source' do
      expect(build(:language, name: 'Warlpiri', code: 'wbp', source: :iso639_3).label).to eq('Warlpiri (wbp) · ISO 639-3')
      expect(build(:language, name: 'Warlpiri', code: 'warl1254', source: :glottolog).label).to eq('Warlpiri (warl1254) · Glottolog')
      expect(build(:language, name: 'Warlpiri', code: 'C15', source: :austlang).label).to eq('Warlpiri (C15) · AUSTLANG')
    end

    it 'marks a glottolog dialect as one' do
      language = build(:language, :glottolog_dialect, name: 'Lajamanu Warlpiri', code: 'laja1237')

      expect(language.label).to eq('Lajamanu Warlpiri (laja1237) · Glottolog dialect')
    end

    it 'never mentions that a language is retired' do
      language = build(:language, name: 'Warlpiri', code: 'wbp', source: :iso639_3, retired: true)

      expect(language.label).to eq('Warlpiri (wbp) · ISO 639-3')
    end
  end

  describe '#source_uri' do
    it 'points at the registry that issued the code' do
      expect(build(:language, code: 'wbp', source: :iso639_3).source_uri).to eq('https://iso639-3.sil.org/code/wbp')
      expect(build(:language, code: 'warl1254', source: :glottolog).source_uri).to eq('https://glottolog.org/resource/languoid/id/warl1254')
      expect(build(:language, code: 'C15', source: :austlang).source_uri).to eq('https://collection.aiatsis.gov.au/austlang/language/C15')
    end

    it 'has nothing to point at before a source is set' do
      expect(described_class.new(code: 'wbp').source_uri).to be_nil
    end
  end

  describe 'the superseded renderings' do
    it 'still return what they always did' do
      language = build(:language, name: 'Warlpiri', code: 'wbp')

      expect(language.name_with_code).to eq('Warlpiri - wbp')
      expect(language.language_archive_link).to eq('http://www.language-archives.org/language/wbp')
    end
  end

  describe 'equivalents' do
    it 'reaches its equivalents from either side of the pair' do
      iso = create(:language, code: 'wbp')
      glottolog = create(:language, :glottolog, code: 'warl1254')
      LanguageEquivalent.create!(language: iso, related_language: glottolog, evidence: ['glottolog:iso'])

      expect(iso.equivalents.count).to eq(1)
      expect(glottolog.equivalents.count).to eq(1)
    end

    it 'refuses a tag pointing at a language that is not there' do
      item = create(:item)

      expect { ItemContentLanguage.create!(item:, language_id: 0) }.to raise_error(ActiveRecord::RecordInvalid)
      expect { ItemContentLanguage.insert_all!([{ item_id: item.id, language_id: 0 }]) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it 'refuses to be deleted while an equivalent points at it' do
      iso = create(:language, code: 'wbp')
      glottolog = create(:language, :glottolog, code: 'warl1254')
      LanguageEquivalent.create!(language: iso, related_language: glottolog, evidence: ['glottolog:iso'])

      expect { iso.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end
  end
end
