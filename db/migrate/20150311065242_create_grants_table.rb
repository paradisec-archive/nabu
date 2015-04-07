class CreateGrantsTable < ActiveRecord::Migration
  def up
    create_table :grants do |t|
      t.belongs_to :collection, index: true
      t.string :grant_identifier, index: true
      t.belongs_to :funding_body, index: true
    end
  end

  def down
    drop_table :grants, if_exists: true
  end
end
