require 'rails_helper'

describe ItemDestructionService, :no_catalog_upload do
  let(:catalog) { Nabu::Catalog.instance }

  context 'when item has no files' do
    let(:item_with_no_files) { create(:item, essences: []) }

    it 'proceeds without errors and can be undone' do
      response = described_class.destroy(item_with_no_files)
      expect(response[:success]).to be(true)
      expect(response[:can_undo]).to be(true)
      expect(response[:messages]).to have_key(:notice)
      expect(response[:messages]).not_to have_key(:error)
    end

    it 'still schedules deletion of the admin metadata, verifying the item prefix' do
      expected_keys = [catalog.item_rocrate_key(item_with_no_files)]

      described_class.destroy(item_with_no_files)

      expect(DeleteCatalogFilesJob).to have_been_enqueued.with(expected_keys, verify_prefix: catalog.item_prefix(item_with_no_files))
    end
  end

  context 'when item has files' do
    let(:essence) { create(:sound_essence) }
    let(:item_with_files) { essence.item }

    it 'schedules deletion of the essence files and admin metadata, verifying the item prefix' do
      expected_keys = [catalog.essence_key(essence), catalog.item_rocrate_key(item_with_files)]

      response = described_class.destroy(item_with_files)

      expect(response[:success]).to be(true)
      expect(response[:can_undo]).to be(false)
      expect(response[:messages][:notice]).to include('file deletion from the archive has been scheduled')
      expect(Item.exists?(item_with_files.id)).to be(false)
      expect(Essence.exists?(essence.id)).to be(false)
      expect(DeleteCatalogFilesJob).to have_been_enqueued.with(expected_keys, verify_prefix: catalog.item_prefix(item_with_files))
    end

    it 'does not schedule file deletion when the item cannot be destroyed' do
      allow(item_with_files).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

      response = described_class.destroy(item_with_files)

      expect(response[:success]).to be(false)
      expect(response[:messages]).to have_key(:error)
      expect(DeleteCatalogFilesJob).not_to have_been_enqueued
    end
  end

  # Regression: essences are removed with delete_all, which skips the `has_one :entity, dependent: :destroy`
  # callback. Without explicit cleanup this leaves orphaned `entities` rows (see Sentry NABU-Q3).
  context 'when the item has denormalised entity rows' do
    let(:essence) { create(:sound_essence) }
    let(:item) { essence.item }

    it 'removes the entity rows for the item and its essences' do
      expect(Entity.where(entity_type: 'Item', entity_id: item.id)).to exist
      described_class.destroy(item)
      expect(Entity.where(entity_type: 'Item', entity_id: item.id)).not_to exist
      expect(Entity.where(entity_type: 'Essence', entity_id: essence.id)).not_to exist
    end
  end
end
