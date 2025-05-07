class ChangeBitrateToBigintInEssences < ActiveRecord::Migration[8.0]
  def up
    change_column :essences, :bitrate, :bigint
  end

  def down
    change_column :essences, :bitrate, :integer
  end
end
