class CreateAccessConditions < ActiveRecord::Migration
  def change
    create_table :access_conditions do |t|
      t.string :name

      t.timestamps
    end
  end
end
