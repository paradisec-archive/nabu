namespace :test_namespaces do
  desc 'List test databases, search indices and catalogue buckets of removed worktrees, and drop them with DELETE=1. Run via bin/test_prune'
  task prune: :environment do
    abort 'Only prunes the local development containers' unless Rails.env.development?

    database = ActiveRecord::Base.connection
    search = Searchkick.client
    s3 = Aws::S3::Resource.new(client: Nabu::Catalog.instance.instance_variable_get(:@s3))

    orphans = Nabu::TestNamespace.orphans(
      worktrees: ENV.fetch('WORKTREES').split("\n"),
      databases: database.select_values('SHOW DATABASES'),
      indices: search.cat.indices(h: 'index', format: 'json').pluck('index'),
      buckets: s3.buckets.map(&:name)
    )

    deleters = {
      databases: ->(name) { database.drop_database(name) },
      indices: ->(name) { search.indices.delete(index: name) },
      buckets: ->(name) { s3.bucket(name).delete! }
    }

    delete = ENV['DELETE'].present?
    orphans.each do |kind, names|
      puts "Orphaned #{kind}:"
      puts '  (none)' if names.empty?
      names.sort.each do |name|
        puts "  #{name}"
        deleters.fetch(kind).call(name) if delete
      end
    end

    puts delete ? 'Dropped the above.' : 'Nothing dropped. Run bin/test_prune --delete to drop the above.'
  end
end
