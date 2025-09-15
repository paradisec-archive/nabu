require 'rails_helper'
require "ostruct"

describe EssenceDestructionService do
  let(:essence) { build(:sound_essence, filename: 'this_file_should_definitely_not_exist') }

  context 'when essence file is present on the server', :skip => "fix this later" do
    it 'proceeds without errors' do
      response = EssenceDestructionService.destroy(essence)
      expect(response).to have_key(:notice)
      expect(response).not_to have_key(:error)
      expect(response[:notice]).to eq('Essence removed successfully, and file deleted from archive (undo not possible).')
    end
  end
end
