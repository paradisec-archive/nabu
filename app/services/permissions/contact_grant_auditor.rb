module Permissions
  # Audits the four permission grant tables for rows that violate the
  # attribution-vs-access separation introduced in the Phase 1 permissions rework:
  #
  #   * contamination — grants whose user is contact-only. Contacts exist purely so
  #     that work can be attributed to them; they never log in and must never hold a grant.
  #   * orphans       — grants whose item/collection has been deleted. These are dead
  #     data-integrity debt left behind by historical bulk-delete paths.
  #
  # `report` is read-only and returns labelled counts for both kinds in separate sections.
  # `cleanup` deletes the contaminated rows. `prune_orphans` is a *separately-invokable*
  # step that deletes the orphan rows — it is deliberately never called by `cleanup`, so the
  # two clean-ups are never conflated.
  #
  # Every query is expressed as a foreign-key subquery (no joins), so each relation is safe to
  # both `count` and `delete_all`. The mutating methods rely on `delete_all` and so skip the
  # models' reindex callbacks; the rake wrappers additionally run inside
  # `Searchkick.callbacks(false)` so the bulk reindex stays an explicit, separate deploy step.
  class ContactGrantAuditor
    # Ordered so reports read collection-then-item, edit-then-read-only.
    GRANTS = {
      collection_edit: { model: CollectionAdmin, owner: Collection, foreign_key: :collection_id },
      collection_read_only: { model: CollectionUser, owner: Collection, foreign_key: :collection_id },
      item_edit: { model: ItemAdmin, owner: Item, foreign_key: :item_id },
      item_read_only: { model: ItemUser, owner: Item, foreign_key: :item_id }
    }.freeze

    def report
      { contamination: contamination_counts, orphans: orphan_counts }
    end

    def contamination_counts
      counts { |config| contaminated(config) }
    end

    def orphan_counts
      counts { |config| orphaned(config) }
    end

    # Deletes grant rows pointing at contact-only users. Returns per-table deleted counts.
    def cleanup
      delete_each { |config| contaminated(config) }
    end

    # Separately-invokable: deletes grant rows pointing at deleted items/collections.
    # Intentionally not called by #cleanup so orphan pruning is never conflated with the
    # contact clean-up. Returns per-table deleted counts.
    def prune_orphans
      delete_each { |config| orphaned(config) }
    end

    private

    def contaminated(config)
      config[:model].where(user_id: User.where(contact_only: true).select(:id))
    end

    def orphaned(config)
      config[:model].where.not(config[:foreign_key] => config[:owner].select(:id))
    end

    def counts
      tallied(GRANTS.transform_values { |config| yield(config).count })
    end

    def delete_each
      tallied(GRANTS.transform_values { |config| yield(config).delete_all })
    end

    def tallied(counts)
      counts.merge(total: counts.values.sum)
    end
  end
end
