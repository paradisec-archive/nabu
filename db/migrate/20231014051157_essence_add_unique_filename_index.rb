class EssenceAddUniqueFilenameIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :essences, %i[item_id filename], unique: true
  end
end
