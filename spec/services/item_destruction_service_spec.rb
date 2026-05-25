require 'rails_helper'

describe ItemDestructionService do
  context 'when item has no files' do
    let(:item_with_no_files) { create(:item, essences: []) }

    it 'proceeds without errors when not deleting files' do
      response = described_class.destroy(item_with_no_files)
      expect(response[:success]).to be(true)
      expect(response[:messages]).to have_key(:notice)
      expect(response[:messages]).not_to have_key(:error)
    end

    it 'proceeds without errors when attempting to delete files' do
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
end
