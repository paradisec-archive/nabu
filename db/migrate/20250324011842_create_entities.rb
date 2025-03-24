class CreateEntities < ActiveRecord::Migration[8.0]
  def change
    create_view :entities
  end
end
