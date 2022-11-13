class CreateLanguages < ActiveRecord::Migration[4.2]
  def change
    create_table :languages, charset: "latin1" do |t|
      t.string :code
      t.string :name
    end

    create_table :collection_languages do |t|
      t.belongs_to :collection
      t.belongs_to :language
    end
    add_index :collection_languages, [:collection_id, :language_id], :unique => :true #, :name => 'collection_fields_of_research_idx'
  end
end
