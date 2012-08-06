ActiveAdmin.register_page "File Processing" do
  content do
    div :class => 'dashboard_section panel' do
      h3 'Collections with at least one item not ready for export (max 20)'
      div :class => 'panel_contents' do
        insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Collection.includes(:items).where(:items => {:metadata_exportable => false}).order('id desc').limit(20) do
          column :identifier
          column :collection_id do |collection|
            link_to collection.identifier, "/collections/#{item.collection.id}"
          end
          column :sample_item do |collection|
            item = collection.items.where(:metadata_exportable => false).first
            link_to item.identifier, "/items/#{item.id}"
          end
          column :title
          default_actions
        end
      end
    end

    div :class => 'dashboard_section panel' do
      h3 'Recently imported files (max 20)'
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
      para 'Note: the machine is set up to check directories once a minute.'
    end
  end
end
