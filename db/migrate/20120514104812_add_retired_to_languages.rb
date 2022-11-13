class AddRetiredToLanguages < ActiveRecord::Migration[4.2]
  def change
    add_column :languages, :retired, :boolean
  end
end
