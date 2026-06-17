module Permissions
  # One-off deploy backfill that preserves access for collectors who would otherwise be locked
  # out once attribution (collector/operator) stops conferring rights in the Phase 1 rework.
  #
  # Targets only *real, active* collectors — `contact_only = false` and a non-null last sign-in.
  # Contacts and never-logged-in users are skipped; operators get nothing.
  #
  #   * collection read-only (collection_users) for each collection's collector
  #   * item read-only (item_users) for items whose collector differs from their collection's
  #     collector (the common case is already covered by the collection grant)
  #
  # Idempotent: only rows not already present are inserted, and the unique indexes guard against
  # any racing duplicate. Inserts go through `insert_all`, which bypasses model callbacks and
  # paper_trail; the whole run is additionally wrapped in `Searchkick.callbacks(false)` so no
  # per-row reindex fires. The bulk reindex is a separate, explicit deploy step.
  class CollectorBackfill
    def call
      Searchkick.callbacks(false) do
        {
          collection_read_only: backfill(CollectionUser, :collection_id, collection_candidates),
          item_read_only: backfill(ItemUser, :item_id, item_candidates)
        }
      end
    end

    private

    # Real users who have actually logged in. Anything else (contacts, never-signed-in) is skipped.
    def real_user_ids
      User.where(contact_only: false).where.not(last_sign_in_at: nil).select(:id)
    end

    def collection_candidates
      Collection.where(collector_id: real_user_ids)
                .pluck(:id, :collector_id)
                .map { |collection_id, user_id| { collection_id:, user_id: } }
    end

    def item_candidates
      Item.joins(:collection)
          .where(collector_id: real_user_ids)
          .where('items.collector_id != collections.collector_id')
          .pluck(:id, :collector_id)
          .map { |item_id, user_id| { item_id:, user_id: } }
    end

    # Inserts only the candidate rows that don't already exist, so re-running grants nothing new.
    # Returns the number of rows actually inserted.
    def backfill(model, owner_key, candidates)
      return 0 if candidates.empty?

      existing = model.where(owner_key => candidates.map { |row| row[owner_key] })
                      .pluck(owner_key, :user_id)
                      .to_set
      fresh = candidates.reject { |row| existing.include?([row[owner_key], row[:user_id]]) }
      return 0 if fresh.empty?

      model.insert_all(fresh)
      fresh.size
    end
  end
end
