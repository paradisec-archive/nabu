class AddOriginatedOnNarrativeToItems < ActiveRecord::Migration[4.2]
  def change
    add_column :items, :originated_on_narrative, :text
  end
end
