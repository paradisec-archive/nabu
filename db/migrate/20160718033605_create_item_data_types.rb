class CreateItemDataTypes < ActiveRecord::Migration
  def change
    create_table :item_data_types, id: false do |t|
      t.references :item
      t.references :data_type
    end
    add_index :item_data_types, :item_id
    add_index :item_data_types, :data_type_id
  end
end
