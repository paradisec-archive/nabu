class AddCreatedByToEssences < ActiveRecord::Migration[8.0]
  def change
    add_reference :essences, :created_by, null: true, index: true
    add_foreign_key :essences, :users, column: :created_by_id
  end
end
