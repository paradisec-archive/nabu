class AddTimestampesToEssences < ActiveRecord::Migration[4.2]
  def change
    change_table :essences do |t|
      t.timestamps
    end

    Essence.reset_column_information

    Item.select(['id', 'created_at', 'updated_at']).find_each do |item|
      Essence.update_all({ created_at: item.created_at, updated_at: item.updated_at }, item_id: item.id)
    end
  end
end
