require 'rails_helper'
require 'open3'

# rubocop:disable RSpec/DescribeClass
describe 'test namespace wiring' do
  let(:probe_env) { { 'RAILS_ENV' => 'test', 'NABU_TEST_NAMESPACE' => 'Wiring Probe', 'TEST_ENV_NUMBER' => '7' } }

  # Both names are fixed at boot, so check them in a freshly booted app. Without CI it skips eager loading, which needs the probe's missing database.
  it 'names the catalogue bucket and search indices from the namespace' do
    script = 'puts Rails.configuration.catalog_bucket, Item.search_index.name'
    output, errors, = Open3.capture3(probe_env.merge('CI' => nil), 'bin/rails', 'runner', script, chdir: Rails.root.to_s)

    expect(output.split).to eq(%w[nabu-catalog-test-wiring-probe-7 items_test_wiring_probe_7]), errors
  end

  describe 'config/database.yml' do
    before { stub_const('ENV', ENV.to_h.merge(probe_env)) }

    def databases(env)
      Rails.application.config.database_configuration.fetch(env).transform_values { |role| role['database'] }
    end

    it 'names the test databases from the namespace' do
      expect(databases('test')).to eq(
        'primary' => 'nabu_test_wiring_probe_7', 'cache' => 'nabu_test_wiring_probe_7_cache', 'queue' => 'nabu_test_wiring_probe_7_queue'
      )
    end

    it 'leaves the development databases alone' do
      expect(databases('development')).to eq('primary' => 'nabu_devel', 'cache' => 'nabu_devel_cache', 'queue' => 'nabu_devel_queue')
    end

    it 'leaves the production databases alone' do
      expect(databases('production')).to eq('primary' => 'nabu', 'cache' => 'nabu_cache', 'queue' => 'nabu_queue')
    end
  end
end
# rubocop:enable RSpec/DescribeClass
