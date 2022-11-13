class AppendEssencesCounterCache < ActiveRecord::Migration[4.2]
  def up
    Item.pluck(:id).each do |id|
      Item.reset_counters(id, :essences)
    end
  end

  def down
    # do nothing
  end
end
