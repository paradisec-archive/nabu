class AddTransformedFlagToEssences < ActiveRecord::Migration
  def change
    add_column :essences, :derived_files_generated, :boolean, default: false
  end
end
