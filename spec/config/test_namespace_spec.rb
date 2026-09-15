require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'test namespace wiring' do
  let(:namespace) { Nabu::TestNamespace.current }

  it 'names the catalogue bucket from the namespace' do
    expect(Rails.configuration.catalog_bucket).to eq(namespace.bucket)
  end

  # Searchkick fixes each model's index name when the model loads, so the suffix must be set first.
  it 'suffixes the search indices from the namespace' do
    expect(Item.search_index.name).to eq(['items_test', namespace.index_suffix].compact.join('_'))
  end

  describe 'config/database.yml' do
    before { stub_const('ENV', ENV.to_h.merge('NABU_TEST_NAMESPACE' => 'Wiring Probe', 'TEST_ENV_NUMBER' => '7')) }

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
