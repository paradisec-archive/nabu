require 'rails_helper'

describe Permissions::ItemEditDedupAuditor do
  let(:user) { create(:user) }
  let(:collection) { create(:collection) }
  let(:item) { create(:item, collection:) }

  # An item-edit grant is redundant when the same user already holds a collection-edit grant on
  # the item's collection — the item grant is a dead duplicate of the cascading collection grant.
  def redundant_grant
    Permission.create!(grantable: collection, user:, level: 'edit')
    Permission.create!(grantable: item, user:, level: 'edit')
  end

  describe '#report' do
    it 'counts item-edit grants redundant against a collection-edit the same user holds' do
      redundant_grant

      expect(described_class.new.report).to eq(redundant_item_edit_grants: 1)
    end

    it 'does not count a genuine item-only edit grant (user holds no collection-edit)' do
      Permission.create!(grantable: item, user:, level: 'edit')

      expect(described_class.new.report).to eq(redundant_item_edit_grants: 0)
    end

    it 'does not count an item-edit grant when another user holds the collection-edit' do
      Permission.create!(grantable: collection, user: create(:user), level: 'edit')
      Permission.create!(grantable: item, user:, level: 'edit')

      expect(described_class.new.report).to eq(redundant_item_edit_grants: 0)
    end

    it 'does not count an item-read grant duplicated by a collection-edit' do
      Permission.create!(grantable: collection, user:, level: 'edit')
      Permission.create!(grantable: item, user:, level: 'read')

      expect(described_class.new.report).to eq(redundant_item_edit_grants: 0)
    end
  end

  describe '#cleanup' do
    it 'deletes only the redundant item-edit grants' do
      redundant_grant

      deleted = described_class.new.cleanup

      aggregate_failures do
        expect(deleted).to eq(deleted_item_edit_grants: 1)
        expect(Permission.where(grantable: item, level: 'edit')).not_to exist
        expect(Permission.where(grantable: collection, level: 'edit')).to exist
      end
    end

    it 'preserves a genuine item-only edit grant where the user holds no collection-edit' do
      genuine = Permission.create!(grantable: item, user:, level: 'edit')

      deleted = described_class.new.cleanup

      aggregate_failures do
        expect(deleted).to eq(deleted_item_edit_grants: 0)
        expect(Permission.exists?(genuine.id)).to be(true)
      end
    end

    it 'preserves an item-only editor while removing a redundant one on the same item' do
      redundant_user = create(:user)
      Permission.create!(grantable: collection, user: redundant_user, level: 'edit')
      redundant = Permission.create!(grantable: item, user: redundant_user, level: 'edit')
      genuine = Permission.create!(grantable: item, user:, level: 'edit')

      deleted = described_class.new.cleanup

      aggregate_failures do
        expect(deleted).to eq(deleted_item_edit_grants: 1)
        expect(Permission.exists?(redundant.id)).to be(false)
        expect(Permission.exists?(genuine.id)).to be(true)
      end
    end
  end
end
