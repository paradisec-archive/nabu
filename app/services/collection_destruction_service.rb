class CollectionDestructionService
  def self.destroy(collection)
    catalog = Nabu::Catalog.instance

    # Snapshot the exact keys before the records are deleted — the job deletes only these.
    keys = catalog.collection_keys(collection)

    essence_ids = Essence.joins(:item).where(items: { collection_id: collection.id }).ids
    item_ids = collection.items.map(&:id)

    # delete_all is efficient but skips ActiveRecord callbacks, so the `dependent: :destroy`
    # cleanup on Item/Essence never fires. Remove the dependent rows ourselves to avoid orphans:
    # the denormalised entity rows and the items' and collection's access grants. Permission has
    # no DB foreign key to its polymorphic grantable, so deleting items would otherwise strand
    # their grant rows.
    Essence.where(id: essence_ids).delete_all
    Permission.where(grantable_type: 'Item', grantable_id: item_ids).delete_all
    Permission.where(grantable_type: 'Collection', grantable_id: collection.id).delete_all
    deleted_items_count = Item.where(collection_id: collection.id).delete_all
    Entity.where(entity_type: 'Essence', entity_id: essence_ids).delete_all
    Entity.where(entity_type: 'Item', entity_id: item_ids).delete_all

    collection.items = [] # force no items

    begin
      collection.destroy!
    rescue StandardError => e
      Rails.logger.error "[DELETE] Failed to destroy collection [#{collection.identifier}]: #{e.message}"

      return {
        success: false,
        messages: {
          error: "Failed to destroy collection: #{e.message}. However #{deleted_items_count} items were deleted"
        }
      }
    end

    DeleteCatalogFilesJob.perform_later(keys, verify_prefix: catalog.collection_prefix(collection))

    Rails.logger.info "[DELETE] Scheduled deletion of #{keys.size} files for collection [#{collection.identifier}]"

    {
      success: true,
      messages: {
        notice: deleted_items_count.zero? ? 'Collection removed; deletion of its archive admin files has been scheduled.' : 'Collection removed; file deletion from the archive has been scheduled (undo not possible).'
      },
      can_undo: deleted_items_count.zero?
    }
  end
end
