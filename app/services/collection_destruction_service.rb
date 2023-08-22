class CollectionDestructionService
  def self.destroy(collection)
    item_identifiers = collection.items.map(&:full_identifier)

    essences = collection.items.map(&:essences).flatten
    essence_ids = essences.map(&:id)

    # use efficient delete since the models don't have any relevant callbacks
    Essence.where(id: essence_ids).delete_all
    deleted_items_count = Item.where(collection_id: collection.id).delete_all

    collection.items = [] # force no items

    begin
      collection.destroy

      # Remove The items just in case
      item_identifiers.each do |item_identifier|
        files = Proxyist.list(item_identifier)
        files.each { |file| Proxyist.delete(item_identifier, file) }

        Rails.logger.info "[DELETE] Removed entire item directory at [#{item}] #{files.size} files"
      end

      files = Proxyist.list(collection.identifier)
      files.each { |file| Proxyist.delete(collection.identifier, file) }
      Rails.logger.info "[DELETE] Removed entire collection directory at [#{collection.identifier}] #{files.size} files"
    rescue => e
      return {
        success: false,
        messages: {
          error: "Failed to destroy collection: #{e.message}. However #{deleted_items_count} items were deleted"
        }
      }
    end

    {
      success: true,
      messages: {
        notice: "Collection removed successfully#{deleted_items_count.zero? ? '' : ' and files deleted from archive (undo not possible)'}."
      },
      can_undo: deleted_items_count.zero?
    }
  end
end
