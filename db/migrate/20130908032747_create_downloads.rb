class CreateDownloads < ActiveRecord::Migration[4.2]
  def change
    create_table :downloads do |t|
      t.belongs_to :user
      t.belongs_to :essence

      t.timestamps
    end
    add_index :downloads, :user_id
    add_index :downloads, :essence_id
  end
end
