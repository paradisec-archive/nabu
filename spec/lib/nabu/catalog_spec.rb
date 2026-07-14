require 'rails_helper'

describe Nabu::Catalog do
  let(:catalog) { described_class.instance }
  let(:collection) { build(:collection, identifier: 'AA1') }
  let(:item) { build(:item, identifier: '001', collection:) }

  describe '#collection_rocrate_key' do
    it 'lives at the collection root' do
      expect(catalog.collection_rocrate_key(collection)).to eq('AA1/ro-crate-metadata.json')
    end
  end

  describe '#item_rocrate_key' do
    it 'lives at the item root' do
      expect(catalog.item_rocrate_key(item)).to eq('AA1/001/ro-crate-metadata.json')
    end
  end

  describe '#deposit_form_key' do
    it 'lives at the collection root, named after the collection' do
      expect(catalog.deposit_form_key(collection)).to eq('AA1/AA1-deposit.pdf')
    end
  end

  describe '#admin_key?' do
    it 'recognises every admin key the builders produce' do
      expect(catalog.admin_key?(catalog.collection_rocrate_key(collection))).to be true
      expect(catalog.admin_key?(catalog.item_rocrate_key(item))).to be true
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
