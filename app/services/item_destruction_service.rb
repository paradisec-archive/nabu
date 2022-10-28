class ItemDestructionService
  def self.destroy(item)
    response = {success: true, messages: {}, can_undo: true}

    # remove essence records
    deleted_essence_count = Essence.where(item_id: item.id).delete_all
    item.essences = [] # force item to have no essences

    item.destroy
    # remove directory and PDSC_ADMIN files on disk
    directory = Nabu::Application.config.archive_directory + "#{item.collection.identifier}/#{item.identifier}/"
    if File.directory?(directory)
      FileUtils.rm_rf(directory)
      puts "[DELETE] Removed entire item directory at [#{directory}]"
    else
      puts "[DELETE] The path [#{directory}] does not refer to an item directory!"
    end

    if deleted_essence_count > 0
      response[:messages][:notice] = 'Item and all its contents removed permanently (no undo possible)'
      response[:can_undo] = false
    else
      response[:messages][:notice] = 'Item removed successfully'
    end

    response
  end

end
