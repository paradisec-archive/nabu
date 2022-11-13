class AddOwnedToItems < ActiveRecord::Migration[4.2]
  def change
    add_column :items, :external, :boolean
  end
end
