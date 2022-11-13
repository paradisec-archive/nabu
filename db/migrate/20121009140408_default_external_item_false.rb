class DefaultExternalItemFalse < ActiveRecord::Migration[4.2]
  def change
    change_column :items, :external, :boolean, :default => false
  end
end
