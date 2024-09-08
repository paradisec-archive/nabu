# rubocop:disable Metrics/BlockLength
namespace :rocrate do
  desc 'Generate ro-crate for a collection and save to S3'
  task :collection, [:identifier] => :environment do |task, args|
    raise 'Please pass a collection identifier' if args[:identifier].nil?

    collection = Collection.find_by(identifier: args[:identifier])
    if collection.nil?
      raise "Collection with identifier #{args[:identifier]} not found"
    end

    collection.update_catalog_metadata

    puts 'Collection ro-crate metadata generated and saved to S3'
  end

  desc 'Generate ro-crate for an item and save to S3'
  task :item, [:identifier] => :environment do |task, args|
    raise 'Please pass an item identifier' if args[:identifier].nil?

    collection_identifier, item_identifier = args[:identifier].split('-')

    collection = Collection.find_by(identifier: collection_identifier)
    if collection.nil?
      raise "Collection with identifier #{collection_identifier} not found"
    end

    item = collection.items.find_by(identifier: item_identifier)
    if item.nil?
      raise "Item with identifier #{item_identifier} not found"
    end

    item.update_catalog_metadata

    puts 'Item ro-crate metadata generated and saved to S3'
  end

  desc 'Generate ro-crate for all collections and save to S3'
  task collections: :environment do
    ActiveJob::Base.logger = Logger.new(nil)

    total = 0
    Collection.find_each do |collection|
      collection.update_catalog_metadata
      total += 1
    end

    puts "Generated ro-crate metadata jobs for #{total} collections and saved to S3"
  end

  desc 'Generate ro-crate for all items and save to S3'
  task items: :environment do
    ActiveJob::Base.logger = Logger.new(nil)

    total = 0
    Item.find_each do |item|
      item.update_catalog_metadata
      total += 1
    end

    puts "Generated ro-crate metadata jobs for #{total} items and saved to S3"
  end
end
