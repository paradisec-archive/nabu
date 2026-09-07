class AddSourcesToLanguages < ActiveRecord::Migration[8.1]
  JOIN_TABLES = %w[collection_languages countries_languages item_content_languages item_subject_languages].freeze

  def up
    reject_orphan_join_rows!

    add_columns
    backfill
    tighten_columns
    swap_code_index

    create_language_equivalents
    create_language_refresh_runs
    add_language_foreign_keys
  end

  def down
    non_iso = select_value("SELECT COUNT(*) FROM languages WHERE source <> 'iso639_3'").to_i
    if non_iso.positive?
      raise ActiveRecord::IrreversibleMigration,
            "#{non_iso} languages come from a source other than ISO 639-3; they have nowhere to go in the old schema"
    end

    JOIN_TABLES.each do |table|
      remove_foreign_key table, :languages, column: :language_id
      remove_index table, column: :language_id if index_exists?(table, :language_id)
    end
    drop_table :language_equivalents
    drop_table :language_refresh_runs

    remove_index :languages, column: %i[code source], unique: true
    add_index :languages, :code, unique: true

    change_column :languages, :retired, :boolean, default: nil, null: true
    remove_column :languages, :source
    remove_column :languages, :dialect
    remove_column :languages, :synonyms
    remove_column :languages, :latitude
    remove_column :languages, :longitude
    remove_column :languages, :previous_latitude
    remove_column :languages, :previous_longitude
    remove_column :languages, :box_origin
  end

  private

  # The restrict foreign keys below cannot be added while a join row points at a language that
  # is gone. MySQL's own error names only the constraint, so count them here and say which table.
  def reject_orphan_join_rows!
    orphans = JOIN_TABLES.filter_map do |table|
      count = select_value(<<~SQL.squish).to_i
        SELECT COUNT(*) FROM #{table} j
        LEFT JOIN languages l ON l.id = j.language_id
        WHERE j.language_id IS NOT NULL AND l.id IS NULL
      SQL
      "#{table}: #{count}" if count.positive?
    end
    return if orphans.empty?

    raise ActiveRecord::IrreversibleMigration,
          "join rows point at languages that no longer exist (#{orphans.join(', ')}); delete them before migrating"
  end

  def add_columns
    add_column :languages, :source, :string
    add_column :languages, :dialect, :boolean
    add_column :languages, :synonyms, :text
    add_column :languages, :latitude, :float
    add_column :languages, :longitude, :float
    add_column :languages, :previous_latitude, :float
    add_column :languages, :previous_longitude, :float
    add_column :languages, :box_origin, :string
  end

  # Bulk statements, so no PaperTrail versions are written for the 7,788 existing rows.
  def backfill
    execute("UPDATE languages SET source = 'iso639_3'")
    execute('UPDATE languages SET dialect = FALSE')
    execute('UPDATE languages SET retired = FALSE WHERE retired IS NULL')
    execute(<<~SQL.squish)
      UPDATE languages SET box_origin = 'hand_set'
      WHERE north_limit IS NOT NULL AND south_limit IS NOT NULL
        AND west_limit IS NOT NULL AND east_limit IS NOT NULL
    SQL
  end

  def tighten_columns
    change_column :languages, :source, :string, null: false
    change_column :languages, :dialect, :boolean, default: false, null: false
    change_column :languages, :retired, :boolean, default: false, null: false
  end

  # The pair index has code first, so lookups by code alone still have an index.
  def swap_code_index
    remove_index :languages, column: :code, unique: true
    add_index :languages, %i[code source], unique: true
  end

  def create_language_equivalents
    create_table :language_equivalents do |t|
      t.integer :language_id, null: false
      t.integer :related_language_id, null: false
      t.json :evidence, null: false

      t.index %i[language_id related_language_id], unique: true, name: 'index_language_equivalents_on_pair'
      t.index :related_language_id
    end

    # Pairs are undirected, so the lower id is always stored first; that plus the unique index
    # above is what makes a pair unique whichever way round it is written.
    add_check_constraint :language_equivalents, 'language_id < related_language_id', name: 'language_equivalents_ordered'
  end

  def create_language_refresh_runs
    create_table :language_refresh_runs do |t|
      t.string :status, null: false, default: 'running'
      t.datetime :started_at
      t.datetime :finished_at
      t.json :sources
      t.text :report, size: :medium
      t.timestamps
    end
  end

  def add_language_foreign_keys
    JOIN_TABLES.each do |table|
      add_index table, :language_id unless index_exists?(table, :language_id)
      add_foreign_key table, :languages, column: :language_id, on_delete: :restrict
    end

    add_foreign_key :language_equivalents, :languages, column: :language_id, on_delete: :restrict
    add_foreign_key :language_equivalents, :languages, column: :related_language_id, on_delete: :restrict
  end
end
