require 'rails_helper'

describe ValidateCatalogDbSyncJob do
  it 'runs the DB sync validator against the production buckets' do
    validator = instance_double(CatalogDbSyncValidatorService)

    allow(CatalogDbSyncValidatorService).to receive(:new).with('prod').and_return(validator)
    expect(validator).to receive(:run)

    described_class.perform_now
  end

  it 'runs on the maintenance queue' do
    expect(described_class.new.queue_name).to eq('maintenance')
  end
end
