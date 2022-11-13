class UseNorthSouthForGeo < ActiveRecord::Migration[4.2]
  def change
    change_table :collections do |t|
      t.float :north_limit
      t.float :south_limit
      t.float :west_limit
      t.float :east_limit
      t.remove :zoom, :latitude, :longitude
    end
    change_table :items do |t|
      t.float :north_limit
      t.float :south_limit
      t.float :west_limit
      t.float :east_limit
      t.remove :zoom, :latitude, :longitude
    end
  end
end
