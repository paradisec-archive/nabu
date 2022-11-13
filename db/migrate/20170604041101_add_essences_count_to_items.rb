class AddEssencesCountToItems < ActiveRecord::Migration[4.2]
  def change
    add_column :items, :essences_count, :integer
  end
end
