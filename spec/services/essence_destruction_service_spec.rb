require 'rails_helper'

describe EssenceDestructionService do
  let(:essence) { build(:sound_essence, filename: 'this_file_should_definitely_not_exist') }

  context 'when essence file is present on the server' do
    before do
      #so there are no surprise directory deletions from the service tests
      allow(FileUtils).to receive(:rm).and_return(nil)
    end

    it 'should proceed without errors' do
      response = EssenceDestructionService.destroy(essence)
      expect(response).to have_key(:notice)
      expect(response).to_not have_key(:error)
      expect(response[:notice]).to eq('Essence removed successfully, and file deleted from archive (undo not possible).')
    end
  end

  context 'when essence file is not present on the server' do
    before do
      # so there are no surprise directory deletions from the service tests
      allow(FileUtils).to receive(:rm).and_raise StandardError.new('No such file or directory @ unlink_internal ')
    end

    it 'should proceed with errors' do
      response = EssenceDestructionService.destroy(essence)
      expect(response).to_not have_key(:notice)
      expect(response).to have_key(:error)
      expect(response[:error]).to eq('Essence removed, but deleting file failed with error: No such file or directory - ')
    end
  end
end
