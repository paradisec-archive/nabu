ActiveAdmin.register_page "File Processing" do
  content do
    div :class => 'dashboard_section panel' do
      h3 'Collections with at least one item not ready for export (max 20)'
      div :class => 'panel_contents' do
        insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Collection.includes(:items).where(:items => {:metadata_exportable => false}).order('collections.id desc').limit(20) do
          column :identifier
          # FIXME USe _path for the URLs below
          column :collection_id do |collection|
            link_to collection.identifier, Rails.application.routes.url_helpers.collection_path(collection) # Have to call the full path here as activeadmin has a collection_path
          end
          column :sample_item do |collection|
            item = collection.items.where(:metadata_exportable => false).first
            link_to item.identifier, [collection, item]
          end
          column :title
          actions
        end
      end
    end

    div :class => 'dashboard_section panel' do
      h3 'Recently imported files (max 20)'
      div :class => 'panel_contents' do
        insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Essence.order('id desc').limit(20) do
          column :id do |essence|
            link_to essence.id, [essence.item.collection, essence.item, essence]
          end
          column :full_identifier
          column :mimetype
          column :size
          column :duration
          column :samplerate
          column :channels
          column :fps
          column :bitrate
          actions
        end
      end
    end

    div :class => 'dashboard_section panel' do
      render 'paths'
      para 'Note: the machine is set up to check directories once every 5 minutes.'
    end
  end
end
