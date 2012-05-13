class AddOwnedToItems < ActiveRecord::Migration
  def change
    add_column :items, :owned, :boolean
  end
end
