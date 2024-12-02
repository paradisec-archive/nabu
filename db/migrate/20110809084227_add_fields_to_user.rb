class AddFieldsToUser < ActiveRecord::Migration[4.2]
  def change
    change_table :users do |t|
      t.string :address
      t.string :address2
      t.string :country
      t.string :phone
      t.boolean :operator, default: false
    end
  end
end
