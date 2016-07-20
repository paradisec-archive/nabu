class CreateDataTypes < ActiveRecord::Migration
  def change
    create_table :data_types do |t|
      t.string :name, null: false, index: true

      # Don't create timestamps
    end
  end
end
