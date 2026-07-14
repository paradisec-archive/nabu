require 'rails_helper'

# `:no_catalog_upload` switches ActiveJob to the test adapter, which the retry example needs
# so a retried job is enqueued rather than executed inline.
describe DeleteCatalogFilesJob, :no_catalog_upload do
  let(:catalog) { Nabu::Catalog.instance }

  before do
    allow(catalog).to receive(:delete_keys) { |keys| keys.size }
    allow(catalog).to receive(:list_keys).and_return([])
  end

  it 'deletes the given keys in batches of at most 1000' do
    keys = (1..2500).map { |n| "X1/001/file-#{n}.wav" }

    expect(catalog).to receive(:delete_keys).with(keys[0, 1000]).ordered
    expect(catalog).to receive(:delete_keys).with(keys[1000, 1000]).ordered
    expect(catalog).to receive(:delete_keys).with(keys[2000, 500]).ordered

    described_class.perform_now(keys)
  end

  it 'does not verify when no prefix is given' do
    expect(catalog).not_to receive(:list_keys)

    described_class.perform_now(['X1/001/file.wav'])
  end

  context 'when a verification prefix is given' do
    it 'reports stray objects to Sentry without deleting them' do
      allow(catalog).to receive(:list_keys).with('X1/').and_return(['X1/stray.bin'])

      expect(Sentry).to receive(:capture_message)
        .with(/X1\//, hash_including(level: :warning, extra: { stray_count: 1, stray_keys: ['X1/stray.bin'] }))
      expect(catalog).to receive(:delete_keys).once

      described_class.perform_now(['X1/001/file.wav'], verify_prefix: 'X1/')
    end

    it 'stays quiet when nothing is left under the prefix' do
      expect(Sentry).not_to receive(:capture_message)

      described_class.perform_now(['X1/001/file.wav'], verify_prefix: 'X1/')
    end
  end

  context 'when deletion fails' do
    it 'retries the job' do
      allow(catalog).to receive(:delete_keys).and_raise('S3 exploded')

      expect { described_class.perform_now(['X1/001/file.wav']) }.to have_enqueued_job(described_class)
    end
  end
end
