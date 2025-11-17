# rubocop:disable Metrics/BlockLength
ActiveAdmin.register_page 'Catalog Report' do
  content do
    year = params.dig(:date, :year) || Time.zone.today.year
    month = params.dig(:date, :month) || Time.zone.today.month
    month = month.to_i
    year = year.to_i
    date = Date.parse("#{year}-#{month}-01")

    data = {
      new_collections: Collection.where(created_at: date.beginning_of_month..date.end_of_month),
      new_items: Item.where(created_at: date.beginning_of_month..date.end_of_month).includes(:collection),
      new_essences: Essence.where(created_at: date.beginning_of_month..date.end_of_month).includes(item: :collection),

      updated_collections: Collection.where(updated_at: date.beginning_of_month..date.end_of_month),
      updated_items: Item.where(updated_at: date.beginning_of_month..date.end_of_month).includes(:collection),
      updated_essences: Essence.where(updated_at: date.beginning_of_month..date.end_of_month).includes(item: :collection)
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
            render partial: 'admin/dashboard/statistics', locals: { date: }
          end
        end
      end
    end

    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      %w[new updated].each do |which|
        div do
          panel "#{which.capitalize} Collections" do
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

    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      %w[new updated].each do |which|
        div do
          panel "#{which.capitalize} Items" do
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

    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      %w[new updated].each do |which|
        div do
          panel "#{which.capitalize} Files" do
            insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, data[:"#{which}_essences"] do
              column :full_identifier do |essence|
                link_to essence.full_identifier, [essence.item.collection, essence.item, essence]
              end
            end
          end
        end
      end
    end

    div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
      div do
        panel 'File Type Metrics' do
          data = Essence
                 .where('created_at <= ?', date.end_of_month)
                 .select('mimetype, COUNT(*) as files, SUM(size) as bytes, SUM(duration) as duration')
                 .group(:mimetype)
                 .order('files desc')

          table_for data do
            column :type
            column :files
            column(:bytes) { |row| number_to_human_size row.bytes }
            column(:duration) { |row| number_to_human_duration row.duration }
          end
        end
      end

      div class: 'grid auto-cols-fr grid-flow-col gap-4 mb-4' do
        panel 'Collection Metrics' do
          data = Collection
                 .select('
                   collections.id AS id,
                   collections.identifier AS identifier,
                   COUNT(DISTINCT items.id) AS items_count,
                   COUNT(DISTINCT essences.id) AS essences_count,
                   SUM(essences.size) AS total_size,
                   SUM(essences.duration) AS total_duration
                 ')
                 .joins('LEFT JOIN items ON items.collection_id = collections.id')
                 .joins('LEFT JOIN essences ON essences.item_id = items.id')
                 .where('collections.created_at <= ?', date.end_of_month)
                 .where('items.created_at <= ? OR items.created_at IS NULL', date.end_of_month)
                 .where('essences.created_at <= ? OR essences.created_at IS NULL', date.end_of_month)
                 .group(:identifier)
                 .order(:identifier)

          table_for data do
            column :identifier
            column 'Items', :items_count
            column 'Files', :essences_count
            column('Bytes', :total_size) { |row| number_to_human_size(row.total_size || 0) }
            column('Duration', :total_duration) { |row| number_to_human_duration(row.total_duration || 0) }
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
