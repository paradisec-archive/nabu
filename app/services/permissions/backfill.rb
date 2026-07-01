module Permissions
  # Deploy-time backfill that fills the polymorphic `permissions` table from the four old
  # membership tables, collapsing them onto the single (user, grantable, level) shape:
  #
  #   * collection_admins -> Collection edit
  #   * collection_users  -> Collection read
  #   * item_admins       -> Item edit
  #   * item_users        -> Item read
  #
  # Contact-only users are skipped defensively so no contaminated grant is re-introduced — the
  # four old tables predate the contact-grant guard and may still hold such rows.
  #
  # Idempotent: only rows not already present in `permissions` are inserted, and the unique index
  # guards against any racing duplicate. Inserts go through `insert_all`, which bypasses model
  # callbacks and paper_trail; the whole run is wrapped in `Searchkick.callbacks(false)` so no
  # per-row reindex fires. The bulk reindex is a separate, explicit deploy step.
  class Backfill
    # Ordered so reports read collection-then-item, edit-then-read-only, matching the auditors.
    SOURCES = {
      collection_edit: { model: CollectionAdmin, grantable_type: 'Collection', foreign_key: :collection_id, level: 'edit' },
      collection_read_only: { model: CollectionUser, grantable_type: 'Collection', foreign_key: :collection_id, level: 'read' },
      item_edit: { model: ItemAdmin, grantable_type: 'Item', foreign_key: :item_id, level: 'edit' },
      item_read_only: { model: ItemUser, grantable_type: 'Item', foreign_key: :item_id, level: 'read' }
    }.freeze

    def call
      Searchkick.callbacks(false) do
        counts = SOURCES.transform_values { |config| backfill(config) }
        counts.merge(total: counts.values.sum)
      end
    end

    private

    def contact_only_users
      User.where(contact_only: true).select(:id)
    end

    # Inserts only the source rows that don't already exist as a permission, so re-running grants
    # nothing new. Returns the number of rows actually inserted.
    def backfill(config)
      candidates = config[:model]
                   .where.not(user_id: contact_only_users)
                   .pluck(config[:foreign_key], :user_id)
                   .map { |grantable_id, user_id| { grantable_type: config[:grantable_type], grantable_id:, user_id:, level: config[:level] } }
      return 0 if candidates.empty?

      existing = Permission.where(grantable_type: config[:grantable_type], level: config[:level])
                           .where(grantable_id: candidates.map { |row| row[:grantable_id] })
                           .pluck(:grantable_id, :user_id)
                           .to_set
      fresh = candidates.reject { |row| existing.include?([row[:grantable_id], row[:user_id]]) }
      return 0 if fresh.empty?

      Permission.insert_all(fresh)
      fresh.size
    end
  end
end
