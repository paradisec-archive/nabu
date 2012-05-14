class AddRetiredToLanguages < ActiveRecord::Migration
  def change
    add_column :languages, :retired, :boolean
  end
end
