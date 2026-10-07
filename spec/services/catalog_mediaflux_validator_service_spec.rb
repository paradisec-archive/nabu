require 'rails_helper'

describe CatalogMediafluxValidatorService do
  let(:s3) { Aws::S3::Client.new(stub_responses: true) }
  let(:run_dir) { 'inventories/catalog/nabu-catalog-prod/CatalogBucketInventory0/2026-10-07T01-00Z/' }
  let(:mediaflux_prefix) { 'asset:/projects/proj-1190_paradisec_backup-1128.4.248/paradisec/' }

  # path => [size, last_modified] as of the S3 inventory run
  let(:inventory) { {} }
  # path => size in the Mediaflux snapshot
  let(:mediaflux) { {} }
  # path => [size, last_modified] as S3 has it now; absent means deleted
  let(:live) { {} }

  def objects_csv
    inventory.map { |path, (size, modified)| ['nabu-catalog-prod', CGI.escape(path), 'v1', 'true', 'false', size, modified].to_csv }.join
  end

  def mediaflux_csv
    rows = mediaflux.map { |path, size| ["#{mediaflux_prefix}#{path}", size].to_csv }
    "SRC_PATH,SRC_LENGTH\n#{rows.join}"
  end

  before do
    travel_to Time.utc(2026, 10, 8, 20)

    allow(Aws::S3::Client).to receive(:new).and_return(s3)

    s3.stub_responses(:list_objects_v2, lambda { |context|
      if context.params[:prefix] == 'mediaflux-inventory/'
        { contents: [{ key: 'mediaflux-inventory/2026-10-07.csv' }], is_truncated: false }
      else
        { common_prefixes: [{ prefix: run_dir }], is_truncated: false }
      end
    })

    s3.stub_responses(:get_object, lambda { |context|
      case context.params[:key]
      when "#{run_dir}manifest.json" then { body: { files: [{ key: 'data/objects.csv.gz' }] }.to_json }
      when 'data/objects.csv.gz' then { body: ActiveSupport::Gzip.compress(objects_csv) }
      when 'mediaflux-inventory/2026-10-07.csv' then { body: mediaflux_csv }
      end
    })

    s3.stub_responses(:head_object, lambda { |context|
      size, modified = live[context.params[:key]]
      size ? { content_length: size, last_modified: Time.iso8601(modified) } : 'NotFound'
    })
  end

  def expect_report(missing:, size_mismatch:)
    expect(AdminMailer).to receive(:with).with(missing:, size_mismatch:).and_call_original

    described_class.new.run
  end

  it 'reports files missing from mediaflux and size mismatches' do
    inventory['AA1/missing.wav'] = [10, '2026-09-01T00:00:00.000Z']
    inventory['AA1/mismatch.json'] = [20, '2026-09-01T00:00:00.000Z']
    inventory['AA1/ok.wav'] = [30, '2026-09-01T00:00:00.000Z']
    mediaflux['AA1/mismatch.json'] = 25
    mediaflux['AA1/ok.wav'] = 30
    live['AA1/missing.wav'] = [10, '2026-09-01T00:00:00Z']
    live['AA1/mismatch.json'] = [20, '2026-09-01T00:00:00Z']

    expect_report(missing: ['AA1/missing.wav'], size_mismatch: [{ path: 'AA1/mismatch.json', s3_size: 20, mediaflux_size: 25 }])
  end

  it 'ignores files the inventory shows as modified on or after the mediaflux snapshot date' do
    inventory['AA1/new.wav'] = [10, '2026-10-07T00:00:00.000Z']

    expect_report(missing: [], size_mismatch: [])
  end

  it 'ignores files modified after the S3 inventory ran but before the mediaflux snapshot' do
    inventory['BC1/ro-crate-metadata.json'] = [3686, '2026-09-24T01:40:46.000Z']
    mediaflux['BC1/ro-crate-metadata.json'] = 7018
    live['BC1/ro-crate-metadata.json'] = [7018, '2026-10-07T11:33:08Z']

    expect_report(missing: [], size_mismatch: [])
  end

  it 'ignores files deleted from S3 since the inventory ran' do
    inventory['AA1/gone.wav'] = [10, '2026-09-01T00:00:00.000Z']

    expect_report(missing: [], size_mismatch: [])
  end

  it 'reports the live S3 size when a file changed before the snapshot date and still mismatches' do
    inventory['AA1/changed.json'] = [20, '2026-09-01T00:00:00.000Z']
    mediaflux['AA1/changed.json'] = 25
    live['AA1/changed.json'] = [22, '2026-10-06T10:00:00Z']

    expect_report(missing: [], size_mismatch: [{ path: 'AA1/changed.json', s3_size: 22, mediaflux_size: 25 }])
  end

  it 'does not report a file whose live S3 size now matches mediaflux' do
    inventory['AA1/fixed.json'] = [20, '2026-09-01T00:00:00.000Z']
    mediaflux['AA1/fixed.json'] = 25
    live['AA1/fixed.json'] = [25, '2026-10-06T10:00:00Z']

    expect_report(missing: [], size_mismatch: [])
  end
end
