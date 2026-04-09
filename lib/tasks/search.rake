# frozen_string_literal: true

namespace :search do
  desc 'Reindex all searchable models (Collection, Item, Essence) with size-aware batching for Essence'
  task reindex: :environment do
    Searchkick.timeout = 60

    [Collection, Item].each do |model|
      puts "Reindexing #{model.name}..."
      model.reindex
      puts "#{model.name} done!"
    end

    puts "\nReindexing Essence (incremental)..."
    Essence.reindex(import: false)

    print 'Importing essences with extracted_text < 50KB...'
    Essence.search_import.where('extracted_text IS NULL OR octet_length(extracted_text) < 51200')
      .find_in_batches(batch_size: 200) { |batch| Essence.search_index.bulk_index(batch); print '.' }
    puts ' Done!'

    print 'Importing essences with extracted_text 50KB - 1MB...'
    Essence.search_import.where('octet_length(extracted_text) >= 51200 AND octet_length(extracted_text) < 1048576')
      .find_in_batches(batch_size: 25) { |batch| Essence.search_index.bulk_index(batch); print '.' }
    puts ' Done!'

    (1..4).each do |mb|
      lower = mb * 1_048_576
      upper = (mb + 1) * 1_048_576
      count = Essence.where('octet_length(extracted_text) >= ? AND octet_length(extracted_text) < ?', lower, upper).count
      next if count.zero?

      print "Importing #{count} essences with extracted_text #{mb}MB - #{mb + 1}MB..."
      Essence.search_import.where('octet_length(extracted_text) >= ? AND octet_length(extracted_text) < ?', lower, upper)
        .find_in_batches(batch_size: 1) { |batch| Essence.search_index.bulk_index(batch); print '.' }
      puts ' Done!'
    end

    count = Essence.where('octet_length(extracted_text) >= ?', 5 * 1_048_576).count
    if count.positive?
      print "Importing #{count} essences with extracted_text > 5MB..."
      Essence.search_import.where('octet_length(extracted_text) >= ?', 5 * 1_048_576)
        .find_in_batches(batch_size: 1) { |batch| Essence.search_index.bulk_index(batch); print '.' }
      puts ' Done!'
    end

    puts "\nAll done!"
  end
end
