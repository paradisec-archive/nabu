class CreateEssences < ActiveRecord::Migration
  def change
    create_table :essences do |t|
      t.belongs_to :item
      t.string     :filename
      t.string     :mimetype
      t.integer    :bitrate
      t.integer    :samplerate
      t.integer    :size, :limit => 8
      t.float      :duration
      t.integer    :channels
      t.integer    :fps
    end
    add_index :essences, :item_id
  end
end
