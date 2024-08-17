require 'rails_helper'

describe User do
  let!(:duplicate_user) { create(:user, first_name: 'Joe', last_name: 'Bloggs') }
  let!(:duplicate_user2) { create(:user, first_name: 'Joe', last_name: 'Bloggs') }

  describe '#all_duplicates' do
    it 'should find multiple entries' do
      expect(User.all_duplicates.count).to have_key(%w[Joe Bloggs])
    end
  end

  describe '#duplicates_of' do
    it 'should find multiple entries with email addresses and ids' do
      dups = User.duplicates_of('Joe', 'Bloggs')
      expect(dups.count).to be > 1
      dups.each do |dup|
        expect(dup.id).to be_present
        expect(dup.email).to be_present
      end
    end
  end
end
