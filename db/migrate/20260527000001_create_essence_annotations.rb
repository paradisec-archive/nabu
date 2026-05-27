class CreateEssenceAnnotations < ActiveRecord::Migration[8.0]
  def change
    create_table :essence_annotations do |t|
      t.integer :annotation_essence_id, null: false
      t.integer :target_essence_id, null: false
      t.timestamps
    end

    add_index :essence_annotations, :annotation_essence_id
    add_index :essence_annotations, :target_essence_id

    add_foreign_key :essence_annotations, :essences, column: :annotation_essence_id, on_delete: :cascade
    add_foreign_key :essence_annotations, :essences, column: :target_essence_id, on_delete: :cascade

    add_index :essence_annotations,
              %i[annotation_essence_id target_essence_id],
              unique: true,
              name: 'index_essence_annotations_unique_pair'
  end
end
