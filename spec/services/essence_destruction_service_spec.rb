require 'spec_helper'

describe EssenceDestructionService do
  let(:essence) { build(:sound_essence, filename: 'this_file_should_definitely_not_exist') }

  context 'when essence file is present on the server' do
    before do
      #so there are no surprise directory deletions from the service tests
      FileUtils.stub(:rm).and_return nil
    end

    it 'should proceed without errors' do
      response = EssenceDestructionService.destroy(essence)
      expect(response).to have_key(:notice)
      expect(response).to_not have_key(:error)
      expect(response[:notice]).to eq('Essence removed successfully, also from archive (undo not possible).')
    end
  end

  context 'when essence file is not present on the server' do
    before do
      #so there are no surprise directory deletions from the service tests
      FileUtils.stub(:rm).and_raise StandardError.new("No such file or directory @ unlink_internal - #{essence.path}")
    end

    it 'should proceed with errors' do
      response = EssenceDestructionService.destroy(essence)
      expect(response).to_not have_key(:notice)
      expect(response).to have_key(:error)
      expect(response[:error]).to eq("Essence removed, but file removing had error: No such file or directory - #{essence.path}")
    end
  end
end