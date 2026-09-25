class CascadeItemDependentsOnDelete < ActiveRecord::Migration[8.1]
  ITEM_DEPENDENT_TABLES = %i[
    item_countries
    item_subject_languages
    item_content_languages
    item_agents
    item_data_categories
    item_data_types
  ].freeze

  def up
    ITEM_DEPENDENT_TABLES.each do |table|
      # Remove orphan rows so the constraint can be added.
      execute(<<~SQL.squish)
        DELETE child FROM #{table} child
        LEFT JOIN items parent ON child.item_id = parent.id
        WHERE parent.id IS NULL
      SQL

      add_foreign_key table, :items, on_delete: :cascade
    end

    # Polymorphic, so there is no column to hang a foreign key on.
    execute(<<~SQL.squish)
      DELETE child FROM comments child
      LEFT JOIN items parent ON child.commentable_id = parent.id
      WHERE child.commentable_type = 'Item' AND parent.id IS NULL
    SQL

    # Historical; Collection still destroys these through callbacks.
    execute(<<~SQL.squish)
      DELETE child FROM collection_languages child
      LEFT JOIN collections parent ON child.collection_id = parent.id
      WHERE parent.id IS NULL
    SQL
  end

  def down
    ITEM_DEPENDENT_TABLES.each do |table|
      remove_foreign_key table, :items
    end
  end
end
