require 'rails_helper'

describe DeleteUnconfirmedUsersJob do
  let!(:confirmed) { create(:user, created_at: 30.days.ago) }
  let!(:recently_unconfirmed) { create(:user, confirmed_at: nil, created_at: 2.days.ago) }
  let!(:old_referenced) { create(:user, confirmed_at: nil, created_at: 30.days.ago) }
  let!(:old_unreferenced) { create(:user, confirmed_at: nil, created_at: 30.days.ago) }

  before do
    create(:user, rights_transferred_to: old_referenced)
    ActionMailer::Base.deliveries.clear
  end

  it 'deletes only old unreferenced unconfirmed users' do
    described_class.perform_now

    expect(User.exists?(old_unreferenced.id)).to be false
    expect(User.exists?(old_referenced.id)).to be true
    expect(User.exists?(recently_unconfirmed.id)).to be true
    expect(User.exists?(confirmed.id)).to be true
  end

  it 'sends the post-deletion report' do
    described_class.perform_now

    subjects = ActionMailer::Base.deliveries.map(&:subject)
    expect(subjects).to include('[NABU Admin] Unconfirmed Users Deleted: 1 accounts removed')
  end

  it 'sends no report when nothing was deleted' do
    old_unreferenced.destroy!

    described_class.perform_now

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it 'rolls back the batch and fails when a user cannot be deleted' do
    undeletable = create(:user, confirmed_at: nil, created_at: 30.days.ago)
    ActionMailer::Base.deliveries.clear
    allow(User).to receive(:unconfirmed).with(older_than: 14.days).and_return([old_unreferenced, undeletable])
    allow(undeletable).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

    expect { described_class.perform_now }.to raise_error(ActiveRecord::RecordNotDestroyed)

    expect(User.exists?(old_unreferenced.id)).to be true
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it 'runs on the maintenance queue' do
    expect(described_class.new.queue_name).to eq('maintenance')
  end
end
