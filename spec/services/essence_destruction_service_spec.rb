require 'rails_helper'

describe EssenceDestructionService, :no_catalog_upload do
  let(:essence) { create(:sound_essence) }

  it 'destroys the record and schedules deletion of its file' do
    key = Nabu::Catalog.instance.essence_key(essence)

    response = described_class.destroy(essence)

    expect(response[:notice]).to include('file deletion from the archive has been scheduled')
    expect(response).not_to have_key(:error)
    expect(Essence.exists?(essence.id)).to be(false)
    expect(DeleteCatalogFilesJob).to have_been_enqueued.with([key])
  end

  it 'does not schedule file deletion when the record cannot be destroyed' do
    allow(essence).to receive(:destroy).and_return(false)

    response = described_class.destroy(essence)

    expect(response).to have_key(:error)
    expect(DeleteCatalogFilesJob).not_to have_been_enqueued
  end
end
