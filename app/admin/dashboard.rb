ActiveAdmin.register_page "Dashboard" do

  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  action_item :cron do
    if File.exist? "#{Rails.root}/tmp/pids/disable_cron"
      link_to 'Enable Cron Jobs!', admin_dashboard_cron_path(:state => 'on'), :class => 'red'
    else
      link_to 'Disable Cron Jobs!', admin_dashboard_cron_path(:state => 'off'), :class => 'green'
    end
  end

  page_action :cron, :method => :get do
    if params[:state] == 'on'
      FileUtils.rm_f "#{Rails.root}/tmp/pids/disable_cron"
      flash[:notice] = 'Enabled Cron Jobs'
    elsif params[:state] == 'off'
      FileUtils.touch "#{Rails.root}/tmp/pids/disable_cron"
      flash[:notice] = 'Disabled Cron Jobs'
    end

    redirect_to admin_root_path
  end

  content :title => 'Dashboard' do

    columns do

      column do
        panel 'Statistics' do
          div do
            render :partial => 'admin/dashboard/statistics', :locals => {:date => Date.today}
          end
        end
      end

      column do
        panel '10 Newest Collections' do
          insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Collection.order('id desc').limit(10) do
            column :identifier do |collection|
              link_to collection.identifier, Rails.application.routes.url_helpers.collection_path(collection) # Have to call the full path here as activeadmin has a collection_path
            end
            column :title
            actions
          end
        end
      end

      column do
        panel '10 Newest Items' do
          insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Item.order('id desc').limit(10) do
            column :full_identifier do |item|
              link_to item.full_identifier, [item.collection, item]
            end
            column :title
            actions
          end
        end
      end
    end

    columns do

      column do
        panel '10 Newest Comments' do
          insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Comment.order('id desc').limit(10) do
            column :item_id do |comment|
              link_to comment.commentable.full_identifier, [comment.commentable.collection, comment.commentable]
            end
            column :body
            column :owner
          end
        end
      end
      column do
        panel '10 Newest Users' do
          insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, User.order('id desc').limit(10) do
            column :id do |user|
              link_to user.id, [:admin, user]
            end
            column :first_name
            column :last_name
          end
        end
      end
      column do
        panel 'Unapproved Comments' do
          insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Comment.unapproved.order('id desc').limit(10) do
            column :item_id do |comment|
              link_to comment.commentable.full_identifier, [comment.commentable.collection, comment.commentable]
            end
            column :body
            column :owner
            actions
            column '', :sortable => false do |comment|
              link_to 'Approve', approve_comment_path(comment), :method => :post
            end
            column '', :sortable => false do |comment|
              link_to 'Spam',    spam_comment_path(comment), :method => :post
            end
          end
        end
      end
    end
  end
end
