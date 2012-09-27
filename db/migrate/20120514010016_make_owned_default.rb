class MakeOwnedDefault < ActiveRecord::Migration
  def change
    change_column :items, :external, :boolean, :default => true
  end
end
