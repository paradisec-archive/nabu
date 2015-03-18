class CreateCountryLatlonBoundary < ActiveRecord::Migration
  def change
    create_table :latlon_boundaries do |t|
      t.belongs_to :country,   :null => false
      t.decimal :east_limit,   :null => false, :precision => 6, :scale => 3
      t.decimal :west_limit,   :null => false, :precision => 6, :scale => 3
      t.decimal :north_limit,   :null => false, :precision => 6, :scale => 3
      t.decimal :south_limit,   :null => false, :precision => 6, :scale => 3
      t.boolean :wrapped, :default => false
    end
    add_index :latlon_boundaries, :country_id
  end
end
