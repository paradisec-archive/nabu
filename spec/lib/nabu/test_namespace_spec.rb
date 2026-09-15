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

    it 'has no suffix' do
      expect(namespace.suffix).to be_nil
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

    it 'uses it as the suffix' do
      expect(namespace.suffix).to eq('1229_test_namespaces')
    end

    it 'appends it to the bucket with hyphens' do
      expect(namespace.bucket).to eq('nabu-catalog-test-1229-test-namespaces')
    end
  end

  context 'with a worker number only' do
    let(:worker) { '3' }

    it 'uses the worker number as the suffix' do
      expect([databases, namespace.suffix, namespace.bucket]).to eq([%w[nabu_test_3 nabu_test_3_cache nabu_test_3_queue], '3', 'nabu-catalog-test-3'])
    end
  end

  context 'with a worktree name and a worker number' do
    let(:name) { 'search' }
    let(:worker) { '2' }

    it 'joins them' do
      expect([namespace.database(:cache), namespace.suffix, namespace.bucket]).to eq(%w[nabu_test_search_2_cache search_2 nabu-catalog-test-search-2])
    end
  end

  describe 'cleaning the worktree name' do
    it 'lowercases and replaces punctuation' do
      expect(described_class.new(name: 'Issue 1204.Search-Labels').suffix).to eq('issue_1204_search_labels')
    end

    it 'collapses repeated underscores and strips them from the ends' do
      expect(described_class.new(name: '--Feature__!!x--').suffix).to eq('feature_x')
    end
  end

  describe 'trimming long worktree names' do
    let(:thirty) { 'a' * 30 }

    it 'leaves names of up to 30 characters alone' do
      expect(described_class.new(name: thirty).suffix).to eq(thirty)
    end

    it 'trims longer names to 30 characters ending in a 6-character hash' do
      expect(described_class.new(name: "#{thirty}b").suffix).to match(/\Aa{23}_\h{6}\z/)
    end

    it 'keeps names sharing a long prefix distinct' do
      suffixes = %w[one two].map { |tail| described_class.new(name: "agent-worktree-for-issue-1229-#{tail}").suffix }

      expect(suffixes.uniq.size).to eq(2)
    end

    it 'does not leave an underscore before the hash' do
      expect(described_class.new(name: "#{'a' * 22}-#{'b' * 10}").suffix).to match(/\Aa{22}_\h{6}\z/)
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

  describe '.orphans' do
    let(:worktrees) { ['1229-test-namespaces'] }

    def orphans(**resources)
      described_class.orphans(worktrees:, **resources)
    end

    context 'with databases' do
      it 'returns those of removed worktrees and keeps those of live ones' do
        databases = %w[nabu_test_1229_test_namespaces nabu_test_1229_test_namespaces_cache nabu_test_gone nabu_test_gone_queue]

        expect(orphans(databases:)[:databases]).to eq(%w[nabu_test_gone nabu_test_gone_queue])
      end

      it "keeps a live worktree's per-worker databases" do
        expect(orphans(databases: %w[nabu_test_1229_test_namespaces_2 nabu_test_1229_test_namespaces_12_cache])[:databases]).to be_empty
      end

      it "never returns the main checkout's, development, production or unrelated databases" do
        databases = %w[nabu_test nabu_test_cache nabu_test_queue nabu_test_2 nabu_test_16_queue nabu_devel nabu_devel_cache nabu nabu_queue oai mysql sys]

        expect(orphans(databases:)[:databases]).to be_empty
      end

      it 'returns the hand-made agent databases' do
        databases = %w[nabu_test_1198 nabu_test_1198_cache nabu_test_1204 nabu_test_1206 nabu_test_w1203]

        expect(orphans(databases:)[:databases]).to eq(databases)
      end
    end

    context 'with search indices' do
      it 'returns those of removed worktrees and keeps those of live ones, including per-worker ones' do
        indices = %w[items_test_1229_test_namespaces_20260915062804472 collections_test_1229_test_namespaces_3_20260915062803907
                     items_test_gone_20260915052833402 essences_test_gone_2_20260915052833959]

        expect(orphans(indices:)[:indices]).to eq(%w[items_test_gone_20260915052833402 essences_test_gone_2_20260915052833959])
      end

      it "never returns the main checkout's, development or system indices" do
        indices = %w[items_test_20260915044524759 items_test_4_20260915044524759 items_development_20260820013605483 items_test
                     .kibana_1 .opendistro_security security-auditlog-2026.09.15 top_queries-2026.09.15-04093]

        expect(orphans(indices:)[:indices]).to be_empty
      end

      it 'returns the hand-made agent indices' do
        indices = %w[collections_test_job1198_20260914232710974 essences_test_w1204_20260915045922556]

        expect(orphans(indices:)[:indices]).to eq(indices)
      end
    end

    context 'with catalogue buckets' do
      it 'returns those of removed worktrees and keeps those of live ones, including per-worker ones' do
        buckets = %w[nabu-catalog-test-1229-test-namespaces nabu-catalog-test-1229-test-namespaces-2 nabu-catalog-test-gone nabu-catalog-test-gone-3]

        expect(orphans(buckets:)[:buckets]).to eq(%w[nabu-catalog-test-gone nabu-catalog-test-gone-3])
      end

      it "never returns the main checkout's, production-named or unrelated buckets" do
        buckets = %w[nabu-catalog-test nabu-catalog-test-2 nabu-catalog-prod nabu-catalog nabu-meta-test]

        expect(orphans(buckets:)[:buckets]).to be_empty
      end
    end
  end
end
