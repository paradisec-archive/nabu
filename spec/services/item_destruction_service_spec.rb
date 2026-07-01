require 'rails_helper'

describe ItemDestructionService do
  context 'when item has no files' do
    let(:item_with_no_files) { create(:item, essences: []) }

    it 'proceeds without errors' do
      response = described_class.destroy(item_with_no_files)
      expect(response[:success]).to be(true)
      expect(response[:messages]).to have_key(:notice)
      expect(response[:messages]).not_to have_key(:error)
    end
  end

  context 'when item has files' do
    let(:essence) { create(:sound_essence) }
    let(:item_with_files) { create(:item, essences: [essence]) }

    context 'when essence files are present on the server' do
      before do
        allow(EssenceDestructionService).to receive(:destroy).and_return({ notice: 'test success' })
      end

      it 'proceeds without errors when attempting to delete files' do
        response = described_class.destroy(item_with_files)
        expect(response[:success]).to be(true)
        expect(response[:messages]).to have_key(:notice)
        expect(response[:messages]).not_to have_key(:error)
        expect(response[:messages][:notice]).to eq('Item and all its contents removed permanently (no undo possible)')
      end
    end
  end

  # Regression: essences are removed with delete_all, which skips the `has_one :entity, dependent: :destroy`
  # callback. Without explicit cleanup this leaves orphaned `entities` rows (see Sentry NABU-Q3).
  context 'when the item has denormalised entity rows', :no_catalog_upload do
    let(:essence) { create(:sound_essence) }
    let(:item) { create(:item, essences: [essence]) }

    before do
      allow(Nabu::Catalog.instance).to receive(:delete_item).and_return(0)
    end

    it 'removes the entity rows for the item and its essences' do
      expect(Entity.where(entity_type: 'Item', entity_id: item.id)).to exist
      described_class.destroy(item)
      expect(Entity.where(entity_type: 'Item', entity_id: item.id)).not_to exist
      expect(Entity.where(entity_type: 'Essence', entity_id: essence.id)).not_to exist
    end
  end
end
