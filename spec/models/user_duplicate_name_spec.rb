require 'rails_helper'

describe User, type: :model do
  before do
    create(:user, first_name: 'Joe', last_name: 'Bloggs')
    create(:user, first_name: 'Joe', last_name: 'Bloggs')
  end

  describe '#all_duplicates' do
    it 'finds multiple entries' do
      expect(described_class.all_duplicates.count).to have_key(%w[Joe Bloggs])
    end
  end

  describe '#duplicates_of' do
    it 'finds multiple entries with email addresses and ids' do
      dups = described_class.duplicates_of('Joe', 'Bloggs')
      expect(dups.count).to be > 1
      dups.each do |dup|
        expect(dup.id).to be_present
        expect(dup.email).to be_present
      end
    end
  end
end
