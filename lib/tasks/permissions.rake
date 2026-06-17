namespace :permissions do
  LABELS = {
    collection_edit: 'collection edit (collection_admins)',
    collection_read_only: 'collection read-only (collection_users)',
    item_edit: 'item edit (item_admins)',
    item_read_only: 'item read-only (item_users)'
  }.freeze

  print_section = lambda do |title, counts|
    puts title
    LABELS.each { |key, label| puts format('  %-44s %d', label, counts.fetch(key)) }
    puts format('  %-44s %d', 'total', counts.fetch(:total))
  end

  desc 'Report grant rows pointing at contact-only users (contamination) or deleted items/collections (orphans)'
  task contact_grants_report: :environment do
    report = Searchkick.callbacks(false) { Permissions::ContactGrantAuditor.new.report }

    print_section.call('Contamination (grants pointing at contact-only users):', report[:contamination])
    puts
    print_section.call('Orphans (grants pointing at deleted items/collections):', report[:orphans])
  end

  desc 'Delete grant rows pointing at contact-only users. Set PRUNE_ORPHANS=true to also prune orphan rows.'
  task contact_grants_cleanup: :environment do
    auditor = Permissions::ContactGrantAuditor.new

    Searchkick.callbacks(false) do
      print_section.call('Deleted contaminated grants (contact-only users):', auditor.cleanup)

      if ENV['PRUNE_ORPHANS'] == 'true'
        puts
        print_section.call('Deleted orphan grants (deleted items/collections):', auditor.prune_orphans)
      else
        puts
        puts 'Orphan rows left untouched. Re-run with PRUNE_ORPHANS=true to prune them.'
      end
    end
  end

  desc 'Backfill read-only grants for real, logged-in collectors (idempotent; no reindex)'
  task collector_backfill: :environment do
    inserted = Permissions::CollectorBackfill.new.call

    puts 'Inserted read-only grants for real, logged-in collectors:'
    puts format('  %-44s %d', 'collection read-only (collection_users)', inserted.fetch(:collection_read_only))
    puts format('  %-44s %d', 'item read-only (item_users)', inserted.fetch(:item_read_only))
  end
end
