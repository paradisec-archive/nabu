class CreateAccessConditions < ActiveRecord::Migration[4.2]
  def change
    create_table :access_conditions do |t|
      t.string :name

      t.timestamps
    end
  end
end
