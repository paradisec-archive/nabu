class CreateDataCategories < ActiveRecord::Migration[4.2]
  def change
    create_table :data_categories, charset: "latin1" do |t|
      t.string :name
    end
    add_index :data_categories, :name, unique: true

    create_table :item_data_categories do |t|
      t.belongs_to :item,   null: false
      t.belongs_to :data_category,   null: false
    end
    add_index :item_data_categories, [:item_id, :data_category_id], unique: :true
  end
end
