# rubocop:disable Metrics/BlockLength
ActiveAdmin.register_page 'File Processing' do
  content do
    div class: 'dashboard_section panel' do
      h3 'Collections with at least one item not ready for export (max 20)'
      div class: 'panel_contents' do
        table_for Collection.includes(:items).where(items: { metadata_exportable: false }).order('collections.identifier asc').limit(20) do
          # FIXME: Use _path for the URLs below
          column :collection do |collection|
            # Have to call the full path here as activeadmin has a collection_path
            link_to collection.identifier, Rails.application.routes.url_helpers.collection_path(collection)
          end
          column :sample_item do |collection|
            item = collection.items.where(metadata_exportable: false).first
            link_to item.identifier, [collection, item]
          end
          column :title
        end
      end
    end

    div class: 'dashboard_section panel' do
      h3 'Recently imported files (max 20)'
      div class: 'panel_contents' do
        table_for Essence.order('id desc').limit(20) do
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
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
