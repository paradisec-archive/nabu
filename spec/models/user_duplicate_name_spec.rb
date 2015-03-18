require 'spec_helper'

describe User do
  describe '#all_duplicates' do
    it 'should find multiple entries' do
      expect(User.all_duplicates.count).to have_key(%w(Ismael Lieberherr))
    end
  end

  describe '#duplicates_of' do
    it 'should find multiple entries with email addresses and ids' do
      dups = User.duplicates_of('Ismael', 'Lieberherr')
      expect(dups.count).to eq(2)
      dups.each do |dup|
        expect(dup.id).to be_present
        expect(dup.email).to be_present
      end
    end
  end
end