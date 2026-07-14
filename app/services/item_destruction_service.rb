class ItemDestructionService
  def self.destroy(item)
    response = { success: true, messages: {}, can_undo: true }

    catalog = Nabu::Catalog.instance
    # Snapshot the exact keys before the records are deleted — the job deletes only these.
    keys = catalog.item_keys(item)

    # remove essence records
    essence_ids = Essence.where(item_id: item.id).ids
    deleted_essence_count = Essence.where(item_id: item.id).delete_all
    # delete_all skips callbacks, so the essences' `has_one :entity, dependent: :destroy` never fires.
    # Clean up the denormalised entity rows ourselves to avoid orphans (the item's own entity row is
    # removed by item.destroy below).
    Entity.where(entity_type: 'Essence', entity_id: essence_ids).delete_all
    item.essences = [] # force item to have no essences

    begin
      item.destroy!
    rescue StandardError => e
      Rails.logger.error "[DELETE] Failed to destroy item [#{item.full_identifier}]: #{e.message}"

      return { success: false, messages: { error: "Failed to destroy item: #{e.message}" }, can_undo: false }
    end

    DeleteCatalogFilesJob.perform_later(keys, verify_prefix: catalog.item_prefix(item))

    Rails.logger.info "[DELETE] Scheduled deletion of #{keys.size} files for item [#{item.full_identifier}]"

    if deleted_essence_count.positive?
      response[:messages][:notice] = 'Item removed; file deletion from the archive has been scheduled (no undo possible)'
      response[:can_undo] = false
    else
      response[:messages][:notice] = 'Item removed; deletion of its archive metadata has been scheduled'
    end

    response
  end
end
