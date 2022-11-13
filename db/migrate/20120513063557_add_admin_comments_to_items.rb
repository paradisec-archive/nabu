class AddAdminCommentsToItems < ActiveRecord::Migration[4.2]
  def change
    add_column :items, :admin_comment, :text
  end
end
