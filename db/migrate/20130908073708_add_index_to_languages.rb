class AddIndexToLanguages < ActiveRecord::Migration
  def change
    add_index :languages, :code, :unique => true
  end
end
