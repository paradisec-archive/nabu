require 'rails_helper'

describe Nabu::Catalog do
  let(:catalog) { described_class.instance }
  let(:collection) { build(:collection, identifier: 'AA1') }
  let(:item) { build(:item, identifier: '001', collection:) }

  describe '#collection_ro_crate_key' do
    it 'lives at the collection root' do
      expect(catalog.collection_ro_crate_key(collection)).to eq('AA1/ro-crate-metadata.json')
    end
  end

  describe '#item_ro_crate_key' do
    it 'lives at the item root' do
      expect(catalog.item_ro_crate_key(item)).to eq('AA1/001/ro-crate-metadata.json')
    end
  end

  describe '#deposit_form_key' do
    it 'lives at the collection root, named after the collection' do
      expect(catalog.deposit_form_key(collection)).to eq('AA1/AA1-deposit.pdf')
    end
  end

  describe '#upload_item_admin' do
    # Every object creation in this bucket starts a Mediaflux backup job, so an identical rewrite
    # costs a whole Fargate task for no change.
    it 'does not rewrite an object whose content is unchanged' do
      catalog.upload_item_admin(item, 'ro-crate-metadata.json', '{"name":"one"}', 'application/json')

      expect(catalog.s3).not_to receive(:put_object)

      catalog.upload_item_admin(item, 'ro-crate-metadata.json', '{"name":"one"}', 'application/json')
    end

    it 'writes when the content has changed' do
      catalog.upload_item_admin(item, 'ro-crate-metadata.json', '{"name":"one"}', 'application/json')

      expect(catalog.s3).to receive(:put_object).and_call_original

      catalog.upload_item_admin(item, 'ro-crate-metadata.json', '{"name":"two"}', 'application/json')
    end

    it 'writes when the object is not there yet' do
      # The bucket outlives a single run, so the key has to be one nothing has written before.
      expect(catalog.s3).to receive(:put_object).and_call_original

      catalog.upload_item_admin(item, "absent-#{SecureRandom.hex(4)}.json", '{"name":"one"}', 'application/json')
    end
  end

  describe '#admin_key?' do
    it 'recognises every admin key the builders produce' do
      expect(catalog.admin_key?(catalog.collection_ro_crate_key(collection))).to be true
      expect(catalog.admin_key?(catalog.item_ro_crate_key(item))).to be true
      expect(catalog.admin_key?(catalog.deposit_form_key(collection))).to be true
    end

    it 'does not match essence keys' do
      expect(catalog.admin_key?('AA1/001/recording.wav')).to be false
    end

    it 'does not match a deposit PDF named after a different collection' do
      expect(catalog.admin_key?('AA1/BB2-deposit.pdf')).to be false
    end
  end
end
