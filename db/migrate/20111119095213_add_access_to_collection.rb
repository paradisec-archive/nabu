class AddAccessToCollection < ActiveRecord::Migration
  def change
    change_table :collections do |t|
      t.belongs_to :access_condition
      t.text :access_narrative
      t.string :metadata_source
      t.string :orthographic_notes
      t.string :media
      t.text :comments
      t.boolean :complete
      t.boolean :private
      t.string :tape_location
      t.boolean :deposit_form_recieved
    end

    create_table :collection_admins do |t|
      t.belongs_to :collection
      t.belongs_to :user
    end
    add_index :collection_admins, :collection_id
    add_index :collection_admins, :user_id
  end
end
