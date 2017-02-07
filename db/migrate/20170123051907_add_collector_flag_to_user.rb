class AddCollectorFlagToUser < ActiveRecord::Migration
  def up
    add_column :users, :collector, :boolean, null: false, default: false
    collector_ids = (Item.pluck(:collector_id) + Collection.pluck(:collector_id)).uniq.sort
    sql = "update users set collector = true where id in (#{collector_ids.join(', ')});"
    execute sql
  end

  def down
    remove_column :users, :collector
  end
end
