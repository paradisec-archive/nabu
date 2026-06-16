class ItemDestructionService
  def self.destroy(item)
    response = { success: true, messages: {}, can_undo: true }

    # remove essence records
    essence_ids = Essence.where(item_id: item.id).ids
    deleted_essence_count = Essence.where(item_id: item.id).delete_all
    # delete_all skips callbacks, so the essences' `has_one :entity, dependent: :destroy` never fires.
    # Clean up the denormalised entity rows ourselves to avoid orphans (the item's own entity row is
    # removed by item.destroy below).
    Entity.where(entity_type: 'Essence', entity_id: essence_ids).delete_all
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
