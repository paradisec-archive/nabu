class DefaultExternalItemFalse < ActiveRecord::Migration
  def change
    change_column :items, :external, :boolean, :default => false
  end
end
