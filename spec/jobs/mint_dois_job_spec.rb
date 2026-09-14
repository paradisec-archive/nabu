require 'rails_helper'

describe MintDoisJob, :no_catalog_upload do
  let(:minter) { instance_double(DoiMintingService) }
  let(:minted) { [] }
  let!(:collection) { create(:collection, private: false) }
  let!(:item) { create(:item, private: false, collection:) }

  before do
    allow(DoiMintingService).to receive(:new).with(false).and_return(minter)
  end

  it 'mints DOIs for every public object that lacks one' do
    allow(minter).to receive(:mint_doi) { |object| minted << object }

    described_class.perform_now

    expect(minted).to contain_exactly(collection, item)
  end

  it 'keeps minting after a failure and then raises naming the failed objects' do
    allow(minter).to receive(:mint_doi) do |object|
      minted << object
      object != collection
    end

    expect { described_class.perform_now }.to raise_error(MintDoisJob::MintingFailed, /#{collection.full_path}/)
    expect(minted).to contain_exactly(collection, item)
  end

  it 'runs on the maintenance queue' do
    expect(described_class.new.queue_name).to eq('maintenance')
  end
end
