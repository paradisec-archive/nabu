require 'digest'

# Names the test databases, search indices and catalogue bucket so that runs from different
# worktrees and parallel workers never share them. Loaded by config/database.yml before Rails
# autoloading, so it must stay plain Ruby.
module Nabu
  class TestNamespace
    MAX_NAME_LENGTH = 30
    HASH_LENGTH = 6

    def self.current
      new(name: ENV['NABU_TEST_NAMESPACE'], worker: ENV['TEST_ENV_NUMBER'])
    end

    # nil for the main checkout and the first CI worker, which keep the plain names
    attr_reader :index_suffix

    def initialize(name: nil, worker: nil)
      suffix = [clean(name.to_s), worker.to_s.delete('^0-9')].reject(&:empty?).join('_')
      @index_suffix = suffix unless suffix.empty?
    end

    def database(role = nil)
      ['nabu_test', index_suffix, role].compact.join('_')
    end

    def bucket
      ['nabu-catalog-test', index_suffix&.tr('_', '-')].compact.join('-')
    end

    private

    def clean(raw)
      cleaned = raw.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/\A_|_\z/, '')
      return cleaned if cleaned.length <= MAX_NAME_LENGTH

      "#{cleaned[0, MAX_NAME_LENGTH - HASH_LENGTH - 1].delete_suffix('_')}_#{Digest::SHA256.hexdigest(raw)[0, HASH_LENGTH]}"
    end
  end
end
