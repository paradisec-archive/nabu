ActiveAdmin.register_page "Activity Log" do
  content do
    div :class => 'dashboard_section panel' do
      h3 'Collection Activity'
      div :class => 'panel_contents' do
        insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Version.where(:item_type => 'Collection').order('created_at desc').limit(10) do

          column :collection_id do |v|
            collection = v.reify
            if collection
              link_to collection.identifier, Rails.application.routes.url_helpers.collection_path(collection)
            else
              'NONE'
            end
          end

          column :event

          column :changed_by do |v|
            u = User.where(:id => v.whodunnit).first
            u.nil? ? 'NA' : u.name
          end

          column :changeset do |v|
            ul do
              next unless v.changeset
              v.changeset.each do |k, vals|
                from, to = vals
                li do
                  b k
                  span ": #{from} => #{to}"
                end
              end
            end
          end
        end

      end
    end
    div :class => 'dashboard_section panel' do
      h3 'Item Activity'
      div :class => 'panel_contents' do
        insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Version.where(:item_type => 'Item').order('created_at desc').limit(10) do

          column :identifier do |v|
            item = v.reify
            if item && item.collection
              link_to item.full_identifier, Rails.application.routes.url_helpers.collection_item_path(item.collection, item)
            else
              'NONE'
            end
          end

          column :event

          column :changed_by do |v|
            u = User.where(:id => v.whodunnit).first
            u.nil? ? 'NA' : u.name
          end

          column :changeset do |v|
            ul do
              v.changeset.each do |k, vals|
                from, to = vals
                li do
                  b k
                  span ": #{from} => #{to}"
                end
              end
            end
          end
        end
      end
    end
  end
end
