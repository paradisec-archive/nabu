module Permissions
  # Item-edit de-dup auditor. After backfill the `permissions` table holds an item-edit grant for
  # every historical `item_admins` row, and the large majority of those duplicate a collection-edit
  # grant the same user already holds on the item's collection. Those duplicates were manufactured
  # by the now-removed item prefill / spreadsheet copy; since Phase 1 made collection-edit cascade
  # to items, they are dead redundant rows.
  #
  # `report` counts exactly the redundant item-edit grants. `cleanup` deletes only those,
  # *preserving* genuine item-only edit grants — an item-edit grant whose user holds no
  # collection-edit grant on that item's collection is real access and is left untouched. The two
  # are separate methods (and separate rake tasks) so the destructive step is confirmed on its own,
  # following the `Permissions::ContactGrantAuditor` report/cleanup shape.
  #
  # Redundancy is resolved in Ruby from two cheap plucks rather than a self-referential DELETE
  # subquery, which MySQL forbids. Deletes go through `delete_all`, skipping model callbacks and
  # paper_trail; the rake wrapper additionally runs inside `Searchkick.callbacks(false)` so the
  # bulk reindex stays an explicit, separate deploy step.
  class ItemEditDedupAuditor
    DELETE_BATCH_SIZE = 10_000

    def report
      { redundant_item_edit_grants: redundant_ids.size }
    end

    # Deletes only the redundant item-edit grants. Returns the number of rows deleted.
    def cleanup
      deleted = redundant_ids.each_slice(DELETE_BATCH_SIZE).sum { |ids| Permission.where(id: ids).delete_all }
      { deleted_item_edit_grants: deleted }
    end

    private

    # Ids of item-edit grants whose user already holds a collection-edit grant on the item's
    # collection. An item-edit grant with no matching collection-edit — or one pointing at a
    # deleted item — is genuine (or orphan) access and is deliberately excluded here.
    def redundant_ids
      collection_edit_pairs = Permission.where(grantable_type: 'Collection', level: 'edit')
                                        .pluck(:grantable_id, :user_id)
                                        .to_set
      return [] if collection_edit_pairs.empty?

      item_collection = Item.where(id: item_edit_grants.select(:grantable_id))
                            .pluck(:id, :collection_id)
                            .to_h

      item_edit_grants.pluck(:id, :grantable_id, :user_id).filter_map do |id, item_id, user_id|
        collection_id = item_collection[item_id]
        id if collection_id && collection_edit_pairs.include?([collection_id, user_id])
      end
    end

    def item_edit_grants
      Permission.where(grantable_type: 'Item', level: 'edit')
    end
  end
end
