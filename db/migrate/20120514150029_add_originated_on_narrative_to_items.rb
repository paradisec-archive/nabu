class AddOriginatedOnNarrativeToItems < ActiveRecord::Migration
  def change
    add_column :items, :originated_on_narrative, :text
  end
end
