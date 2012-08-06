ActiveAdmin::Dashboards.build do

  section 'Statistics', :priority => 0 do
    div do
      render 'admin/dashboard/statistics'
    end
  end

  section '10 Newest Collections', :priority => 10 do
    insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Collection.order('id desc').limit(10) do
      column :id do |collection|
        link_to collection.id, "/collections/#{collection.id}"
      end
      column :identifier
      column :title
      default_actions
    end
  end

  section '10 Newest Items', :priority => 20 do
    insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Item.order('id desc').limit(10) do
      column :id do |item|
        link_to item.id, "/items/#{item.id}"
      end
      column :full_identifier
      column :title
      default_actions
    end
  end

  section '10 Newest Comments', :priority => 30 do
    insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Comment.order('id desc').limit(10) do
      id_column
      column :body
      column :owner
    end
  end

  section 'Unapproved Comments', :priority => 40, :if => Proc.new { Comment.unapproved.count > 0 } do
    insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Comment.unapproved.order('id desc').limit(10) do
      id_column
      column :body
      column :owner
      default_actions
      column '', :sortable => false do |comment|
        link_to 'Approve', approve_comment_path(comment)
      end
      column '', :sortable => false do |comment|
        link_to 'Spam',    spam_comment_path(comment)
      end

    end
  end

  section '10 Newest Users', :priority => 50 do
    insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, User.order('id desc').limit(10) do
      column :id do |user|
        link_to user.id, "/admin/users/#{user.id}"
      end
      column :first_name
      column :last_name
    end
  end
end
