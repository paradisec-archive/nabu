class RemoveDerivedFilesGeneratedFromEssences < ActiveRecord::Migration
  def up
    remove_column :essences, :derived_files_generated
  end

  def down
    add_column :essences, :derived_files_generated, :boolean
  end
end
