class MakeOwnedDefault < ActiveRecord::Migration
  def change
    change_column :items, :boolean, :default => true
    change_column :external => false
  end
end
