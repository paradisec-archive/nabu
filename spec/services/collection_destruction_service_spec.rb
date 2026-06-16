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
end
