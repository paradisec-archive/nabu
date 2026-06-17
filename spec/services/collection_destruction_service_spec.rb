require 'rails_helper'

describe CollectionDestructionService do
  # Regression: items and essences are removed with delete_all, which skips the
  # `has_one :entity, dependent: :destroy` callback. Without explicit cleanup this leaves orphaned
  # `entities` rows that later blow up the Oni entities endpoint (see Sentry NABU-Q3).
  context 'when the collection has denormalised entity rows', :no_catalog_upload do
    let(:collection) { create(:collection) }
    let(:item) { create(:item, collection:) }
    let(:essence) { create(:sound_essence, item:) }

    before do
      allow(Nabu::Catalog.instance).to receive_messages(delete_item: 0, delete_collection: 0)
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
  # cleanup on item_admins/item_users. Combined with the collection's own collection_users
  # read-only grants, this previously left orphaned membership/grant rows behind.
  context 'when the collection and its items have membership grants', :no_catalog_upload do
    let(:collection) { create(:collection) }
    let(:item) { create(:item, collection:) }
    let(:grantee) { create(:user) }

    before do
      allow(Nabu::Catalog.instance).to receive_messages(delete_item: 0, delete_collection: 0)
      collection.collection_users << CollectionUser.new(user: grantee)
      item.item_admins << ItemAdmin.new(user: grantee)
      item.item_users << ItemUser.new(user: grantee)
    end

    it 'removes the items edit and read-only membership rows and the collection read-only grants' do
      expect(described_class.destroy(collection)[:success]).to be(true)
      expect(ItemAdmin.where(item_id: item.id)).not_to exist
      expect(ItemUser.where(item_id: item.id)).not_to exist
      expect(CollectionUser.where(collection_id: collection.id)).not_to exist
    end
  end
end
