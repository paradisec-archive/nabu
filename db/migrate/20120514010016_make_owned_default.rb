class MakeOwnedDefault < ActiveRecord::Migration[4.2]
  def change
    change_column :items, :external, :boolean, :default => true
  end
end
