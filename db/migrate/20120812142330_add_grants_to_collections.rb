class AddGrantsToCollections < ActiveRecord::Migration
  def change

    create_table :funding_bodies do |t|
      t.string :name, :null => false
      t.string :key_prefix
      t.timestamps
    end

    change_table :collections do |t|
      t.string :grant_identifier
      t.belongs_to :funding_body
    end
  end

end
