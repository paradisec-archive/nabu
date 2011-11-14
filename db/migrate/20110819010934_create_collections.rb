class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.string :identifier, :null => false
      t.string :title, :null => false
      t.text :description, :null => false
      t.belongs_to :collector, :null => false
      t.belongs_to :university
      t.belongs_to :field_of_research, :null => false
      t.belongs_to :collection_country, :null => false
      t.belongs_to :collection_language, :null => false
      t.string :region
      t.float :latitude
      t.float :longitude
      t.integer :zoom

      t.timestamps
    end
    add_index :collections, :identifier, :unique => true
    add_index :collections, :collector_id
    add_index :collections, :university_id
    add_index :collections, :field_of_research_id
    add_index :collections, :collection_country_id
  end
end
