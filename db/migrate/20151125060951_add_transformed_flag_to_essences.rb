class AddTransformedFlagToEssences < ActiveRecord::Migration[4.2]
  def change
    add_column :essences, :derived_files_generated, :boolean, default: false
  end
end
