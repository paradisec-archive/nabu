# frozen_string_literal: true

ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  content title: proc { I18n.t('active_admin.dashboard') } do
    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      div do
        panel 'Statistics' do
          div do
            render partial: 'admin/dashboard/statistics', locals: { date: Date.today }
          end
        end
      end

      div do
        panel '10 Newest Collections' do
          table_for Collection.order('id desc').limit(10) do
            column :identifier do |collection|
              # Have to call the full path here as activeadmin has a collection_path
              link_to collection.identifier, Rails.application.routes.url_helpers.collection_path(collection)
            end
            column :title
            # actions
          end
        end
      end

      div do
        panel '10 Newest Items' do
          table_for Item.order('id desc').limit(10) do
            column :full_identifier do |item|
              link_to item.full_identifier, [item.collection, item]
            end
            column :title
            # actions
          end
        end
      end
    end

    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      div do
        panel '10 Newest Comments' do
          table_for Comment.order('id desc').limit(10) do
            column :item_id do |comment|
              link_to comment.commentable.full_identifier, [comment.commentable.collection, comment.commentable]
            end
            column :body
            column :owner
          end
        end
      end
      div do
        panel '10 Newest Users' do
          table_for User.order('id desc').limit(10) do
            column :id do |user|
              link_to user.id, [:admin, user]
            end
            column :first_name
            column :last_name
          end
        end
      end
     div do
        panel 'Unapproved Comments' do
          table_for Comment.unapproved.order('id desc').limit(10) do
            column :item_id do |comment|
              link_to comment.commentable.full_identifier, [comment.commentable.collection, comment.commentable]
            end
            column :body
            column :owner
            # actions
            column '', sortable: false do |comment|
              link_to 'Approve', approve_comment_path(comment), method: :post
            end
            column '', sortable: false do |comment|
              link_to 'Spam',    spam_comment_path(comment), method: :post
            end
          end
        end
      end
    end
  end
end
