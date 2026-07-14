require 'rails_helper'

describe CollectionDestructionService, :no_catalog_upload do
  let(:collection) { create(:collection) }
  let(:item) { create(:item, collection:) }
  let(:essence) { create(:sound_essence, item:) }

  context 'when scheduling file deletion' do
    before do
      essence # materialise the collection -> item -> essence graph
    end

    it 'schedules deletion of every essence and admin file, verifying the collection prefix' do
      catalog = Nabu::Catalog.instance
      expected_keys = [
        catalog.essence_key(essence),
        catalog.item_rocrate_key(item),
        catalog.collection_rocrate_key(collection),
        catalog.deposit_form_key(collection)
      ]

      response = described_class.destroy(collection)

      expect(response[:success]).to be(true)
      expect(response[:can_undo]).to be(false)
      expect(response[:messages][:notice]).to include('file deletion from the archive has been scheduled')
      expect(Collection.exists?(collection.id)).to be(false)
      expect(Item.exists?(item.id)).to be(false)
      expect(Essence.exists?(essence.id)).to be(false)
      expect(DeleteCatalogFilesJob).to have_been_enqueued.with(expected_keys, verify_prefix: catalog.collection_prefix(collection))
    end
  end

  context 'when the collection has no items' do
    it 'can be undone and still schedules deletion of the admin files' do
      response = described_class.destroy(collection)

      expect(response[:success]).to be(true)
      expect(response[:can_undo]).to be(true)
      expect(DeleteCatalogFilesJob).to have_been_enqueued
    end
  end

  context 'when the collection cannot be destroyed' do
    it 'does not schedule file deletion' do
      allow(collection).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

      response = described_class.destroy(collection)

      expect(response[:success]).to be(false)
      expect(response[:messages]).to have_key(:error)
      expect(DeleteCatalogFilesJob).not_to have_been_enqueued
    end
  end

  # Regression: items and essences are removed with delete_all, which skips the
  # `has_one :entity, dependent: :destroy` callback. Without explicit cleanup this leaves orphaned
  # `entities` rows that later blow up the Oni entities endpoint (see Sentry NABU-Q3).
  context 'when the collection has denormalised entity rows' do
    before do
      essence # materialise the collection -> item -> essence graph (and their entity rows)
    end

    it 'removes the entity rows for the collection, items and essences' do
      expect(described_class.destroy(collection)[:success]).to be(true)
      expect(Entity.where(entity_type: 'Collection', entity_id: collection.id)).not_to exist
      expect(Entity.where(entity_type: 'Item', entity_id: item.id)).not_to exist
      expect(Entity.where(entity_type: 'Essence', entity_id: essence.id)).not_to exist
    end
  end

  # Regression: items are removed with delete_all, which bypasses the `dependent: :destroy`
  # cleanup on their permissions. Combined with the collection's own grants, and because
  # Permission has no database foreign key to its polymorphic grantable, this would otherwise
  # leave orphaned grant rows behind.
  context 'when the collection and its items have access grants' do
    let(:grantee) { create(:user) }

    before do
      collection.users << grantee
      item.admins << grantee
      item.users << grantee
    end

    it 'removes the items edit and read-only grants and the collection grants' do
      expect(described_class.destroy(collection)[:success]).to be(true)
      expect(Permission.where(grantable: item)).not_to exist
      expect(Permission.where(grantable: collection)).not_to exist
    end
  end
end
