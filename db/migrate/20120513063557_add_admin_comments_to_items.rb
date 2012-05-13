class AddAdminCommentsToItems < ActiveRecord::Migration
  def change
    add_column :items, :admin_comment, :text
  end
end
