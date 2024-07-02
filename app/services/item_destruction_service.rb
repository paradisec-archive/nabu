class ItemDestructionService
  def self.destroy(item)
    response = { success: true, messages: {}, can_undo: true }

    # remove essence records
    deleted_essence_count = Essence.where(item_id: item.id).delete_all
    item.essences = [] # force item to have no essences

    item.destroy

    count = Nabu::Catalog.instance.delete_item(item)

    Rails.logger.info "[DELETE] Removed entire item directory at [#{item.full_identifier}]: #{count} files"

    if deleted_essence_count.positive?
      response[:messages][:notice] = 'Item and all its contents removed permanently (no undo possible)'
      response[:can_undo] = false
    else
      response[:messages][:notice] = 'Item removed successfully'
    end

    response
  end
end
