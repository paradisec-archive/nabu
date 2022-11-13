class CreateDataTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :data_types do |t|
      t.string :name, null: false, index: true

      # Don't create timestamps
    end
  end
end
