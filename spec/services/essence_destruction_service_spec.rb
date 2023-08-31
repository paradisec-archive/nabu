require 'rails_helper'

describe EssenceDestructionService do
  let(:essence) { build(:sound_essence, filename: 'this_file_should_definitely_not_exist') }

  context 'when essence file is present on the server' do
    before do
      allow(Proxyist).to receive(:delete_object).and_return(OpenStruct.new(code: '204'))
    end

    it 'should proceed without errors' do
      response = EssenceDestructionService.destroy(essence)
      expect(response).to have_key(:notice)
      expect(response).to_not have_key(:error)
      expect(response[:notice]).to eq('Essence removed successfully, and file deleted from archive (undo not possible).')
    end
  end

  context 'when essence file is not present on the server' do
    it 'should proceed with errors' do
      response = EssenceDestructionService.destroy(essence)
      expect(response).to_not have_key(:notice)
      expect(response).to have_key(:error)
      expect(response[:error]).to eq('Essence removed, but deleting file failed: Not Found')
    end
  end
end
