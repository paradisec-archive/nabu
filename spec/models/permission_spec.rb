require 'rails_helper'

describe Permission, type: :model do
  let(:user) { create(:user) }

  describe 'contact-grant guard (replaces the four-model version)' do
    # Every (grantable, level) combination the four old membership tables covered.
    %i[collection item].each do |grantable|
      %w[read edit].each do |level|
        context "when granting #{level} on a #{grantable}" do
          let(:grantable_record) { create(grantable) }

          it 'is valid when granted to a real user' do
            permission = described_class.new(grantable: grantable_record, user: create(:user), level:)

            expect(permission).to be_valid
          end

          it 'is invalid when granted to a contact-only user' do
            permission = described_class.new(grantable: grantable_record, user: create(:user, :contact_only), level:)

            aggregate_failures do
              expect(permission).not_to be_valid
              expect(permission.errors[:user]).to include('cannot be a contact-only user; contacts can be attributed but not granted access')
            end
          end
        end
      end
    end
  end

  describe 'level enum' do
    it 'exposes read and edit' do
      expect(described_class.levels).to eq('read' => 'read', 'edit' => 'edit')
    end

    it 'requires a level' do
      permission = described_class.new(grantable: create(:collection), user:)

      aggregate_failures do
        expect(permission).not_to be_valid
        expect(permission.errors[:level]).to be_present
      end
    end
  end

  describe 'uniqueness' do
    let(:collection) { create(:collection) }

    it 'rejects a duplicate (user, grantable, level) grant' do
      described_class.create!(grantable: collection, user:, level: 'edit')

      expect(described_class.new(grantable: collection, user:, level: 'edit')).not_to be_valid
    end

    it 'allows the same user to hold read and edit on the same grantable' do
      described_class.create!(grantable: collection, user:, level: 'read')

      expect(described_class.new(grantable: collection, user:, level: 'edit')).to be_valid
    end
  end

  describe 'reindex scope' do
    it 'is registered on after_commit' do
      expect(described_class._commit_callbacks.map(&:filter)).to include(:reindex_search_documents)
    end

    it 'reindexes a granted collection, its items and its essences' do
      collection = create(:collection)
      items = collection.items
      essences = collection.essences
      allow(collection).to receive_messages(items:, essences:)

      aggregate_failures do
        expect(collection).to receive(:reindex).with(mode: :async)
        expect(items).to receive(:reindex).with(mode: :async)
        expect(essences).to receive(:reindex).with(mode: :async)
      end

      described_class.new(grantable: collection, user:, level: 'edit').send(:reindex_search_documents)
    end

    it 'reindexes a granted item, its collection and its essences' do
      item = create(:item)
      collection = item.collection
      essences = item.essences
      allow(item).to receive_messages(collection:, essences:)

      aggregate_failures do
        expect(item).to receive(:reindex).with(mode: :async)
        expect(collection).to receive(:reindex).with(mode: :async)
        expect(essences).to receive(:reindex).with(mode: :async)
      end

      described_class.new(grantable: item, user:, level: 'edit').send(:reindex_search_documents)
    end
  end

  describe 'paper_trail' do
    it 'is versioned' do
      expect(described_class.reflect_on_association(:versions)).to be_present
    end
  end
end
