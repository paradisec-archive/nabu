class AddLatLongToLanguage < ActiveRecord::Migration
  def change
    change_table :languages do |t|
      t.float :north_limit
      t.float :south_limit
      t.float :west_limit
      t.float :east_limit
    end
  end
end
