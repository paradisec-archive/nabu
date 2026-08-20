require 'rails_helper'

# The admin flag is a nil-falsy ivar, so a producer that stops setting it downgrades the crate to
# the public shape rather than raising.
describe CatalogMetadataJob, :no_catalog_upload do
  let(:catalog) { Nabu::Catalog.instance }

  # additionalType appears only on the root entity of either template.
  def uploaded_crate(record)
    is_item = record.is_a?(Item)
    uploaded = nil
    upload = is_item ? :upload_item_admin : :upload_collection_admin
    allow(catalog).to receive(upload) { |_record, _filename, data, _type| uploaded = data }

    described_class.perform_now(record, is_item)

    JSON.parse(uploaded)['@graph'].find { |node| node['additionalType'] }
  end

  # The literal, not the constant: renaming the constant must not move the key already in S3.
  it 'writes the item crate under the admin metadata filename' do
    item = create(:item)

    expect(catalog).to receive(:upload_item_admin)
      .with(item, 'ro-crate-metadata.json', kind_of(String), 'application/json')

    described_class.perform_now(item, true)
  end

  it 'includes private metadata in the item crate' do
    item = create(:item, ingest_notes: 'Tape was mouldy', private: true)

    crate = uploaded_crate(item)

    expect(crate['paradisec:ingestNotes']).to eq('Tape was mouldy')
    expect(crate['private']).to be true
  end

  it 'includes private metadata in the collection crate' do
    collection = create(:collection, comments: 'Deposited under embargo', private: true)

    crate = uploaded_crate(collection)

    expect(crate['comment']).to eq('Deposited under embargo')
    expect(crate['private']).to be true
  end
end
