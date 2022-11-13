class AddIndexToLanguages < ActiveRecord::Migration[4.2]
  def change
    add_index :languages, :code, :unique => true
  end
end
