class ConvertEntitiesViewToTable < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      DROP VIEW IF EXISTS entities;
    SQL

    create_table :entities do |t|
      t.string :entity_type, null: false
      t.integer :entity_id, null: false
      t.string :member_of
      t.string :title
      t.date :originated_on
      t.string :media_types, limit: 1000
      t.boolean :private, default: false, null: false
      t.integer :items_count, default: 0, null: false
      t.integer :essences_count, default: 0, null: false

      t.timestamps
    end

    add_index :entities, %i[entity_type entity_id], unique: true
    add_index :entities, %i[entity_type member_of]
    add_index :entities, :member_of
  end

  def down
    drop_table :entities
  end
end
