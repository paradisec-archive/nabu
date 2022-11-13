class AddDoiToAllCatalogLevels < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :doi, :string, unique: true
    add_column :items, :doi, :string, unique: true
    add_column :essences, :doi, :string, unique: true
  end
end
