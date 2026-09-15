require 'digest'

# Separates test resources per worktree and parallel worker. Loaded by config/database.yml before autoloading, so plain Ruby only.
module Nabu
  class TestNamespace
    MAX_NAME_LENGTH = 30
    HASH_LENGTH = 6

    DATABASE_PREFIX = 'nabu_test'.freeze
    BUCKET_PREFIX = 'nabu-catalog-test'.freeze
    # Searchkick's <model>_<env>, with the models named so a worktree name ending in "test" can't pass for one
    INDEX_PREFIX = '(collections|items|essences)_test'.freeze
    INDEX_TIMESTAMP = '_\d{17}'.freeze
    # At most 3 digits, so hand-made databases named after issues aren't mistaken for the main checkout's workers
    WORKER_PATTERN = '(_\d{1,3})?'.freeze

    NAMESPACED_PATTERNS = {
      databases: /\A#{DATABASE_PREFIX}_/,
      indices: /\A#{INDEX_PREFIX}_.+#{INDEX_TIMESTAMP}\z/,
      buckets: /\A#{BUCKET_PREFIX}-/
    }.freeze

    def self.current
      new(name: ENV['NABU_TEST_NAMESPACE'], worker: ENV['TEST_ENV_NUMBER'])
    end

    def self.orphans(worktrees:, **resources)
      live = [nil, *worktrees].map { |worktree| new(name: worktree) }

      resources.to_h do |kind, names|
        [kind, names.select { |name| name.match?(NAMESPACED_PATTERNS.fetch(kind)) && live.none? { |namespace| namespace.owns?(kind, name) } }]
      end
    end

    # nil for the main checkout and the first CI worker, which keep the plain names
    attr_reader :suffix

    def initialize(name: nil, worker: nil)
      suffix = [clean(name.to_s), worker.to_s.delete('^0-9')].reject(&:empty?).join('_')
      @suffix = suffix unless suffix.empty?
    end

    def database(role = nil)
      [DATABASE_PREFIX, suffix, role].compact.join('_')
    end

    def bucket
      [BUCKET_PREFIX, suffix&.tr('_', '-')].compact.join('-')
    end

    def owns?(kind, name)
      name.match?(owned_pattern(kind))
    end

    private

    def owned_pattern(kind)
      case kind
      when :databases then /\A#{database}#{WORKER_PATTERN}(_cache|_queue)?\z/
      when :indices then /\A#{[INDEX_PREFIX, suffix].compact.join('_')}#{WORKER_PATTERN}#{INDEX_TIMESTAMP}\z/
      when :buckets then /\A#{bucket}#{WORKER_PATTERN.tr('_', '-')}\z/
      end
    end

    def clean(raw)
      cleaned = raw.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/\A_|_\z/, '')
      return cleaned if cleaned.length <= MAX_NAME_LENGTH

      "#{cleaned[0, MAX_NAME_LENGTH - HASH_LENGTH - 1].delete_suffix('_')}_#{Digest::SHA256.hexdigest(raw)[0, HASH_LENGTH]}"
    end
  end
end
