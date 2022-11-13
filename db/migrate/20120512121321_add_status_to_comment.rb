class AddStatusToComment < ActiveRecord::Migration[4.2]
  def change
    change_table :comments do |t|
      t.string :status
    end

    Comment.reset_column_information
    Comment.update_all :status => 'approved'
  end
end
