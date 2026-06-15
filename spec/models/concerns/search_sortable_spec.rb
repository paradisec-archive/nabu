require 'rails_helper'

describe SearchSortable do
  # Use any model that mixes in the concern.
  describe '.natural_sort_key' do
    it 'returns nil for nil' do
      expect(Collection.natural_sort_key(nil)).to be_nil
    end

    it 'downcases so sorting is case-insensitive' do
      expect(Collection.natural_sort_key('AaZ')).to eq('aaz')
    end

    it 'zero-pads numeric runs so lexicographic order matches numeric order' do
      keys = %w[AA2 AA10 AA1].map { |id| Collection.natural_sort_key(id) }
      expect(keys.sort).to eq(%w[AA1 AA2 AA10].map { |id| Collection.natural_sort_key(id) })
    end

    it 'pads each numeric run independently in compound identifiers' do
      expect(Collection.natural_sort_key('AA1-2')).to eq('aa000000000001-000000000002')
    end

    it 'orders long date-style runs correctly against short ones' do
      short = Collection.natural_sort_key('AA1-5')
      long = Collection.natural_sort_key('AA1-20041004001')
      expect([long, short].sort).to eq([short, long])
    end
  end
end
