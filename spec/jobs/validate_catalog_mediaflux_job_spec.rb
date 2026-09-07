require 'rails_helper'

describe ValidateCatalogMediafluxJob do
  it 'runs the Mediaflux validator' do
    validator = instance_double(CatalogMediafluxValidatorService)

    allow(CatalogMediafluxValidatorService).to receive(:new).with(no_args).and_return(validator)
    expect(validator).to receive(:run)

    described_class.perform_now
  end

  it 'runs on the maintenance queue' do
    expect(described_class.new.queue_name).to eq('maintenance')
  end
end
