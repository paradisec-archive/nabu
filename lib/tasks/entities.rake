namespace :entities do
  desc 'Backfill entities table from existing collections, items, and essences'
  task backfill: :environment do
    batch_size = 1000
    now = Time.current

    # Get IDs of records that already have entities
    existing_collection_ids = Entity.where(entity_type: 'Collection').pluck(:entity_id)
    existing_item_ids = Entity.where(entity_type: 'Item').pluck(:entity_id)
    existing_essence_ids = Entity.where(entity_type: 'Essence').pluck(:entity_id)

    puts 'Backfilling Collections...'
    Collection.where.not(id: existing_collection_ids).includes(:items, :essences).in_batches(of: batch_size) do |batch|
      records = batch.map do |collection|
        {
          entity_type: 'Collection',
          entity_id: collection.id,
          member_of: nil,
          title: collection.title,
          originated_on: collection.created_at&.to_date,
          media_types: collection.essences.distinct.pluck(:mimetype).compact.sort.join(',').presence,
          private: collection.private || false,
          items_count: collection.items.size,
          essences_count: collection.essences.size,
          created_at: now,
          updated_at: now
        }
      end
      Entity.insert_all(records) if records.any?
      print '.'
    end
    puts "\nCreated #{Entity.where(entity_type: 'Collection').count} Collection entities"

    puts 'Backfilling Items...'
    Item.where.not(id: existing_item_ids).includes(:collection, :essences).in_batches(of: batch_size) do |batch|
      records = batch.map do |item|
        {
          entity_type: 'Item',
          entity_id: item.id,
          member_of: item.collection&.identifier,
          title: item.title,
          originated_on: item.originated_on,
          media_types: item.essences.distinct.pluck(:mimetype).compact.sort.join(',').presence,
          private: item.private || false,
          items_count: 0,
          essences_count: item.essences.size,
          created_at: now,
          updated_at: now
        }
      end
      Entity.insert_all(records) if records.any?
      print '.'
    end
    puts "\nCreated #{Entity.where(entity_type: 'Item').count} Item entities"

    puts 'Backfilling Essences...'
    Essence.where.not(id: existing_essence_ids).includes(item: :collection).in_batches(of: batch_size) do |batch|
      records = batch.map do |essence|
        {
          entity_type: 'Essence',
          entity_id: essence.id,
          member_of: essence.item&.full_identifier,
          title: essence.filename,
          originated_on: essence.item&.originated_on,
          media_types: essence.mimetype,
          private: essence.item&.private? || essence.item&.collection&.private? || false,
          items_count: 0,
          essences_count: 0,
          created_at: now,
          updated_at: now
        }
      end
      Entity.insert_all(records) if records.any?
      print '.'
    end
    puts "\nCreated #{Entity.where(entity_type: 'Essence').count} Essence entities"

    puts 'Backfill complete!'
  end
end
