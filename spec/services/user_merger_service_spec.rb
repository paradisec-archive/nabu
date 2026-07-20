require 'rails_helper'

describe UserMergerService do
  let(:user) { create(:user) }
  let(:duplicates) { create_list(:user, 3) }
  let(:duplicate_ids) { duplicates.collect(&:id) }

  context 'when merging a user' do
    context 'with itself' do
      it 'does not perform any actions' do
        expect(Item).not_to receive(:update_all)
        expect(ItemAgent).not_to receive(:update_all)

        expect(user).not_to receive(:destroy)
        expect(user).not_to receive(:save)

        described_class.new(user, [user]).call
      end
    end

    context 'with empty array' do
      it 'does not perform any actions' do
        expect(Item).not_to receive(:update_all)
        expect(ItemAgent).not_to receive(:update_all)

        expect(user).not_to receive(:destroy)
        expect(user).not_to receive(:save)

        described_class.new(user, []).call
      end
    end

    context 'with nil' do
      it 'does not perform any actions' do
        expect(Item).not_to receive(:update_all)
        expect(ItemAgent).not_to receive(:update_all)

        expect(user).not_to receive(:destroy)
        expect(user).not_to receive(:save)

        described_class.new(user, nil).call
      end
    end

    context 'with duplicate users holding permissions' do
      let(:collection) { create(:collection) }
      let(:item) { create(:item) }

      it 'moves grants to the primary user, dropping ones the primary already holds' do
        Permission.create!(user:, grantable: collection, level: :read)
        Permission.create!(user: duplicates[0], grantable: collection, level: :read)
        Permission.create!(user: duplicates[0], grantable: collection, level: :edit)
        Permission.create!(user: duplicates[1], grantable: item, level: :edit)

        described_class.new(user, duplicates).call

        expect(User.where(id: duplicate_ids)).to be_empty
        grants = user.permissions.reload.map { |permission| [permission.grantable, permission.level] }
        expect(grants).to contain_exactly([collection, 'read'], [collection, 'edit'], [item, 'edit'])
      end
    end
  end
end
