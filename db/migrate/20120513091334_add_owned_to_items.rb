class AddOwnedToItems < ActiveRecord::Migration
  def change
    add_column :items, :external, :boolean
  end
end
