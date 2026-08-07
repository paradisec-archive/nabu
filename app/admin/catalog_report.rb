# rubocop:disable Metrics/BlockLength
ActiveAdmin.register_page 'Catalog Report' do
  content do
    style do
      text_node <<~CSS
        .scrollable-panel {
          max-height: 400px;
          overflow-y: auto;
        }

        @media print {
          .scrollable-panel {
            max-height: none;
            overflow-y: visible;
          }
        }
      CSS
    end

    scroll_style = 'max-height: 400px; overflow-y: auto;'
    year = params.dig(:date, :year) || Time.zone.today.year
    month = params.dig(:date, :month) || Time.zone.today.month
    month = month.to_i
    year = year.to_i
    date = Date.parse("#{year}-#{month}-01")

    month_range = date.beginning_of_month..date.end_of_month
    mimetype_stats = Essence.mimetype_stats(date.end_of_month)

    # Loaded up front so the summary panel can total them in Ruby rather than re-querying per figure
    data = {
      new_collections: Collection.where(created_at: month_range).to_a,
      new_items: Item.where(created_at: month_range).includes(:collection).to_a,
      new_essences: Essence.where(created_at: month_range).includes(item: :collection).to_a,

      updated_collections: Collection.where(updated_at: month_range).to_a,
      updated_items: Item.where(updated_at: month_range).includes(:collection).to_a,
      updated_essences: Essence.where(updated_at: month_range).includes(item: :collection).to_a
    }

    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      div do
        panel "Catalog report for #{date.strftime('%B %Y')}" do
          render partial: 'form', locals: { date:, year:, month: }
        end
      end
    end

    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      div do
        panel 'Summary' do
          render partial: 'summary', locals: { date:, data: }
        end
      end

      div do
        panel 'Statistics' do
          div do
            render partial: 'admin/dashboard/statistics',
                  locals: { date:, essence_stats: Essence.archive_stats(date.end_of_month, mimetype_stats) }
          end
        end
      end
    end

    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      %w[new updated].each do |which|
        div do
          panel "#{which.capitalize} Collections" do
            div class: 'scrollable-panel' do
              table_for data[:"#{which}_collections"] do
                column :identifier do |collection|
                  # Have to call the full path here as activeadmin has a collection_path
                  link_to collection.identifier, Rails.application.routes.url_helpers.collection_path(collection)
                end
                column :title
              end
            end
          end
        end
      end
    end

    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      %w[new updated].each do |which|
        div do
          panel "#{which.capitalize} Items" do
            div class: 'scrollable-panel' do
              table_for data[:"#{which}_items"] do
                column :full_identifier do |item|
                  link_to item.full_identifier, [item.collection, item]
                end
                column :title
              end
            end
          end
        end
      end
    end

    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      %w[new updated].each do |which|
        div do
          panel "#{which.capitalize} Files" do
            div class: 'scrollable-panel' do
              table_for data[:"#{which}_essences"] do
                column :full_identifier do |essence|
                  link_to essence.full_identifier, [essence.item.collection, essence.item, essence]
                end
              end
            end
          end
        end
      end
    end

    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      div do
        panel 'File Type Metrics' do
          table_for mimetype_stats do
            column('Mimetype') { |row| row[:mimetype] }
            column('Files') { |row| row[:files] }
            column('Bytes') { |row| number_to_human_size row[:bytes] }
            column('Duration') { |row| number_to_human_duration row[:duration] }
          end
        end
      end

      div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
        panel 'Collection Metrics' do
          as_of = date.end_of_month

          # Aggregating each level separately avoids a collections/items/essences fan-out join
          item_counts = Item.where(created_at: ..as_of).group(:collection_id).count
          essence_stats = Essence
                          .joins(:item)
                          .where(created_at: ..as_of, items: { created_at: ..as_of })
                          .group('items.collection_id')
                          .pluck(Arel.sql('items.collection_id, COUNT(*), SUM(essences.size), SUM(essences.duration)'))
                          .to_h { |collection_id, count, size, duration| [collection_id, [count, size, duration]] }

          data = Collection.where(created_at: ..as_of).order(:identifier).pluck(:id, :identifier).map do |id, identifier|
            count, size, duration = essence_stats.fetch(id, [0, 0, 0])
            { identifier:, items_count: item_counts.fetch(id, 0), essences_count: count, total_size: size || 0, total_duration: duration || 0 }
          end

          table_for data do
            column('Identifier') { |row| row[:identifier] }
            column('Items') { |row| row[:items_count] }
            column('Files') { |row| row[:essences_count] }
            column('Bytes') { |row| number_to_human_size(row[:total_size]) }
            column('Duration') { |row| number_to_human_duration(row[:total_duration]) }
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
