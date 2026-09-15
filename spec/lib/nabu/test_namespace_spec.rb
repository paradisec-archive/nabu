require_relative '../../../lib/nabu/test_namespace'

describe Nabu::TestNamespace do
  subject(:namespace) { described_class.new(name:, worker:) }

  let(:name) { nil }
  let(:worker) { nil }
  let(:databases) { [namespace.database, namespace.database(:cache), namespace.database(:queue)] }

  shared_examples 'the plain names' do
    it 'uses the plain database names' do
      expect(databases).to eq(%w[nabu_test nabu_test_cache nabu_test_queue])
    end

    it 'has no index suffix' do
      expect(namespace.index_suffix).to be_nil
    end

    it 'uses the plain bucket name' do
      expect(namespace.bucket).to eq('nabu-catalog-test')
    end
  end

  context 'without a worktree name or worker number' do
    it_behaves_like 'the plain names'
  end

  context 'with blank inputs' do
    let(:name) { '' }
    let(:worker) { '' }

    it_behaves_like 'the plain names'
  end

  context 'with a worktree name' do
    let(:name) { '1229-test-namespaces' }

    it 'inserts it after nabu_test' do
      expect(databases).to eq(%w[nabu_test_1229_test_namespaces nabu_test_1229_test_namespaces_cache nabu_test_1229_test_namespaces_queue])
    end

    it 'uses it as the index suffix' do
      expect(namespace.index_suffix).to eq('1229_test_namespaces')
    end

    it 'appends it to the bucket with hyphens' do
      expect(namespace.bucket).to eq('nabu-catalog-test-1229-test-namespaces')
    end
  end

  context 'with a worker number only' do
    let(:worker) { '3' }

    it 'uses the worker number as the suffix' do
      expect([databases, namespace.index_suffix, namespace.bucket]).to eq([%w[nabu_test_3 nabu_test_3_cache nabu_test_3_queue], '3', 'nabu-catalog-test-3'])
    end
  end

  context 'with a worktree name and a worker number' do
    let(:name) { 'search' }
    let(:worker) { '2' }

    it 'joins them' do
      expect([namespace.database(:cache), namespace.index_suffix, namespace.bucket]).to eq(%w[nabu_test_search_2_cache search_2 nabu-catalog-test-search-2])
    end
  end

  describe 'cleaning the worktree name' do
    it 'lowercases and replaces punctuation' do
      expect(described_class.new(name: 'Issue 1204.Search-Labels').index_suffix).to eq('issue_1204_search_labels')
    end

    it 'collapses repeated underscores and strips them from the ends' do
      expect(described_class.new(name: '--Feature__!!x--').index_suffix).to eq('feature_x')
    end
  end

  describe 'trimming long worktree names' do
    let(:thirty) { 'a' * 30 }

    it 'leaves names of up to 30 characters alone' do
      expect(described_class.new(name: thirty).index_suffix).to eq(thirty)
    end

    it 'trims longer names to 30 characters ending in a 6-character hash' do
      expect(described_class.new(name: "#{thirty}b").index_suffix).to match(/\Aa{23}_\h{6}\z/)
    end

    it 'keeps names sharing a long prefix distinct' do
      suffixes = %w[one two].map { |tail| described_class.new(name: "agent-worktree-for-issue-1229-#{tail}").index_suffix }

      expect(suffixes.uniq.size).to eq(2)
    end

    it 'does not leave an underscore before the hash' do
      expect(described_class.new(name: "#{'a' * 22}-#{'b' * 10}").index_suffix).to match(/\Aa{22}_\h{6}\z/)
    end
  end

  describe 'name limits' do
    let(:name) { 'An Extremely Long Worktree Name For A Very Involved Piece Of Work' }
    let(:worker) { '128' }

    it 'keeps database names within the MySQL limit' do
      expect(databases.map(&:length)).to all(be <= 64)
    end

    it 'keeps the bucket name valid for S3' do
      expect(namespace.bucket).to match(/\A[a-z0-9][a-z0-9-]{1,61}[a-z0-9]\z/)
    end
  end
end
