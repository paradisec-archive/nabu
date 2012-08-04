ActiveAdmin.register_page "File Processing" do
  content do
    div :class => 'dashboard_section panel' do
      h3 "Collections with example item not ready for export (max 20)"
      div :class => 'panel_contents' do      
        insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Item.where(:metadata_exportable => false).group(:collection_id).order('id desc').limit(20) do
          column :full_identifier
          column :collection_id do |item|
            link_to item.collection.identifier, "/collections/#{item.collection.id}"
          end
          column :id do |item|
            link_to item.identifier, "/items/#{item.id}"
          end
          column :title
          default_actions
        end
      end
    end

    div :class => 'dashboard_section panel' do
      h3 "Recently imported files (max 20)"
      div :class => 'panel_contents' do
        insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Essence.order('id desc').limit(20) do
          column :id do |essence|
            link_to essence.id, "/essences/#{essence.id}"
          end
          column :full_identifier
          column :mimetype
          column :size
          column :duration
          column :samplerate
          column :channels
          column :fps
          column :bitrate
          default_actions
        end
      end
    end

    div :class => 'dashboard_section panel' do
      render 'paths'
    end    
  end
end