class UpdateEntitiesToVersion6 < ActiveRecord::Migration[8.0]
  def change
    update_view :entities, version: 6, revert_to_version: 5
  end
end
