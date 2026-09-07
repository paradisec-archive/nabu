require 'rails_helper'

describe UnconfirmedUsersService do
  describe '.delete_old_users' do
    let!(:confirmed) { create(:user, created_at: 30.days.ago) }
    let!(:recently_unconfirmed) { create(:user, confirmed_at: nil, created_at: 2.days.ago) }
    let!(:old_referenced) { create(:user, confirmed_at: nil, created_at: 30.days.ago) }
    let!(:old_unreferenced) { create(:user, confirmed_at: nil, created_at: 30.days.ago) }

    before do
      create(:user, rights_transferred_to: old_referenced)
      ActionMailer::Base.deliveries.clear
    end

    it 'deletes only old unreferenced unconfirmed users' do
      described_class.delete_old_users

      expect(User.exists?(old_unreferenced.id)).to be false
      expect(User.exists?(old_referenced.id)).to be true
      expect(User.exists?(recently_unconfirmed.id)).to be true
      expect(User.exists?(confirmed.id)).to be true
    end

    it 'sends the post-deletion report' do
      described_class.delete_old_users

      subjects = ActionMailer::Base.deliveries.map(&:subject)
      expect(subjects).to include(a_string_starting_with('[NABU Admin] Unconfirmed Users Deleted:'))
    end
  end
end
