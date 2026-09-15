namespace :test_namespaces do
  desc 'List test databases, search indices and catalogue buckets of removed worktrees, and drop them with DELETE=1. Run via bin/test_prune'
  task prune: :environment do
    abort 'Only prunes the local development containers' unless Rails.env.development?

    connection = ActiveRecord::Base.connection
    search_client = Searchkick.client
    s3 = Aws::S3::Resource.new(client: Nabu::Catalog.instance.s3)

    orphans = Nabu::TestNamespace.orphans(
      worktrees: ENV.fetch('WORKTREES').split("\n"),
      databases: connection.select_values('SHOW DATABASES'),
      indices: search_client.cat.indices(h: 'index', format: 'json').pluck('index'),
      buckets: s3.buckets.map(&:name)
    )

    delete = ENV['DELETE'].present?
    orphans.each do |kind, names|
      puts "Orphaned #{kind}:"
      puts '  (none)' if names.empty?
      names.sort.each do |name|
        puts "  #{name}"
        next unless delete

        case kind
        when :databases then connection.drop_database(name)
        when :indices then search_client.indices.delete(index: name)
        when :buckets then s3.bucket(name).delete!
        end
      end
    end

    puts delete ? 'Dropped the above.' : 'Nothing dropped. Run bin/test_prune --delete to drop the above.'
  end
end
