class CollectionDestructionService
  def self.destroy(collection)
    essences = collection.items.map(&:essences).flatten
    essence_ids = essences.map(&:id)

    # use efficient delete since the models don't have any relevant callbacks
    Essence.where(id: essence_ids).delete_all
    deleted_items_count = Item.where(collection_id: collection.id).delete_all

    collection.items = [] # force no items

    begin
      collection.destroy

      directory = Nabu::Application.config.archive_directory + "#{collection.identifier}"
      if File.directory?(directory)
        FileUtils.rm_rf(directory)
        puts "[DELETE] Removed entire collection directory at [#{directory}]"
      else
        puts "[DELETE] The path [#{directory}] does not refer to a collection directory!"
      end
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
        notice: "Collection removed successfully#{deleted_items_count == 0 ? '' : ' and files deleted from archive (undo not possible)'}."
      },
      can_undo: deleted_items_count == 0
    }
  end
end
