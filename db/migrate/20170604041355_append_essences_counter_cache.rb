class AppendEssencesCounterCache < ActiveRecord::Migration
  def up
    Item.pluck(:id).each do |id|
      Item.reset_counters(id, :essences)
    end
  end

  def down
    # do nothing
  end
end
