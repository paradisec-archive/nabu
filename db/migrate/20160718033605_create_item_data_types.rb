class CreateItemDataTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :item_data_types do |t|
      t.references :item, null: false
      t.references :data_type, null: false
    end
    add_index :item_data_types, :item_id
    add_index :item_data_types, :data_type_id
  end
end
