class AddEssencesCountToItems < ActiveRecord::Migration
  def change
    add_column :items, :essences_count, :integer
  end
end
