require 'rails_helper'

describe Permissions::Backfill do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:collection) { create(:collection) }
  let(:item) { create(:item, collection:) }

  describe '#call' do
    it 'maps the four old membership tables onto permissions with the correct level' do
      CollectionAdmin.create!(collection:, user:)
      CollectionUser.create!(collection:, user: other_user)
      ItemAdmin.create!(item:, user:)
      ItemUser.create!(item:, user: other_user)

      described_class.new.call

      aggregate_failures do
        expect(Permission.find_by(grantable: collection, user:).level).to eq('edit')
        expect(Permission.find_by(grantable: collection, user: other_user).level).to eq('read')
        expect(Permission.find_by(grantable: item, user:).level).to eq('edit')
        expect(Permission.find_by(grantable: item, user: other_user).level).to eq('read')
      end
    end

    it 'reports per-source and total inserted counts' do
      CollectionAdmin.create!(collection:, user:)
      ItemAdmin.create!(item:, user: other_user)

      inserted = described_class.new.call

      expect(inserted).to eq(collection_edit: 1, collection_read_only: 0, item_edit: 1, item_read_only: 0, total: 2)
    end

    it 'skips contact-only users so no contaminated grant is re-introduced' do
      contact = create(:user, :contact_only)
      # The old tables predate the contact-grant guard, so a contaminated row is inserted directly.
      CollectionAdmin.new(collection:, user: contact).save!(validate: false)
      ItemAdmin.new(item:, user: contact).save!(validate: false)

      inserted = described_class.new.call

      aggregate_failures do
        expect(Permission.where(user: contact)).not_to exist
        expect(inserted[:total]).to eq(0)
      end
    end

    it 'is idempotent — re-running inserts nothing new' do
      CollectionAdmin.create!(collection:, user:)
      ItemUser.create!(item:, user: other_user)

      described_class.new.call
      second_run = described_class.new.call

      aggregate_failures do
        expect(second_run[:total]).to eq(0)
        expect(Permission.count).to eq(2)
      end
    end

    it 'leaves an existing collection-edit grant untouched while backfilling the rest' do
      Permission.create!(grantable: collection, user:, level: 'edit')
      CollectionAdmin.create!(collection:, user:)
      ItemUser.create!(item:, user: other_user)

      inserted = described_class.new.call

      aggregate_failures do
        expect(inserted).to eq(collection_edit: 0, collection_read_only: 0, item_edit: 0, item_read_only: 1, total: 1)
        expect(Permission.where(grantable: collection, user:, level: 'edit').count).to eq(1)
      end
    end
  end
end
