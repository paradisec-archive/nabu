class MakeOwnedDefault < ActiveRecord::Migration
  def change
    change_column :items, :owned, :boolean, :default => true
  end
end
