class UpdateEntitiesToVersion4 < ActiveRecord::Migration[8.0]
  def change
    update_view :entities, version: 4, revert_to_version: 3
  end
end
