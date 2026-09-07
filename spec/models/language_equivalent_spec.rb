require 'rails_helper'

describe LanguageEquivalent, type: :model do
  let(:iso) { create(:language, code: 'wbp', name: 'Warlpiri') }
  let(:glottolog) { create(:language, :glottolog, code: 'warl1254', name: 'Warlpiri') }

  it 'stores a pair written either way round the same way' do
    equivalent = described_class.create!(language: glottolog, related_language: iso, evidence: ['glottolog:iso'])

    expect(equivalent.language_id).to eq([iso.id, glottolog.id].min)
    expect(equivalent.related_language_id).to eq([iso.id, glottolog.id].max)
  end

  it 'rejects the same pair written the other way round' do
    described_class.create!(language: iso, related_language: glottolog, evidence: ['glottolog:iso'])

    expect(described_class.new(language: glottolog, related_language: iso, evidence: ['name'])).not_to be_valid
  end

  it 'rejects a language paired with itself' do
    expect(described_class.new(language: iso, related_language: iso, evidence: ['name'])).not_to be_valid
  end

  it 'rejects evidence no seed produces' do
    expect(described_class.new(language: iso, related_language: glottolog, evidence: ['a hunch'])).not_to be_valid
  end

  it 'rejects a pair with no evidence behind it' do
    expect(described_class.new(language: iso, related_language: glottolog, evidence: [])).not_to be_valid
  end

  it 'keeps every tag it was given' do
    equivalent = described_class.create!(language: iso, related_language: glottolog, evidence: %w[glottolog:iso name])

    expect(equivalent.reload.evidence).to eq(%w[glottolog:iso name])
  end

  it 'finds the pairs a language is in from either side' do
    austlang = create(:language, :austlang, code: 'C15', name: 'Warlpiri')
    described_class.create!(language: iso, related_language: glottolog, evidence: ['glottolog:iso'])
    described_class.create!(language: austlang, related_language: iso, evidence: ['name'])

    expect(described_class.involving(iso).count).to eq(2)
    expect(described_class.involving(austlang).count).to eq(1)
  end
end
