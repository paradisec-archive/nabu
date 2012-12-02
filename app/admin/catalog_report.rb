ActiveAdmin.register_page 'Catalog Report' do


  content do
    year = params[:year] || Date.today.year
    month = params[:month] || Date.today.month
    month = month.to_i
    year = year.to_i
    date = Date.parse("#{year}-#{month}-01")

    data = {
      :new_collections => Collection.where('created_at >= ? AND created_at <= ?', date.beginning_of_month, date.end_of_month),
      :new_items       => Item.where('created_at >= ? AND created_at <= ?', date.beginning_of_month, date.end_of_month),
      :new_essences    => Essence.where('created_at >= ? AND created_at <= ?', date.beginning_of_month, date.end_of_month),

      :updated_collections => Collection.where('updated_at >= ? AND updated_at <= ?', date.beginning_of_month, date.end_of_month),
      :updated_items       => Item.where('updated_at >= ? AND updated_at <= ?', date.beginning_of_month, date.end_of_month),
      :updated_essences    => Essence.where('updated_at >= ? AND updated_at <= ?', date.beginning_of_month, date.end_of_month),
    }

    columns do
      column do
        panel "Catalog report for #{date.strftime('%B %Y')}" do
          render :partial => 'form', :locals => {:date => date, :year  => year, :month => month}
        end
      end
    end

    columns do
      column do
        panel 'Summary' do
          render :partial => 'summary', :locals => {:date => date, :data => data}
        end
      end

      column do
        panel 'Statistics' do
          div do
            render :partial => 'admin/dashboard/statistics', :locals => {:date => date}
          end
        end
      end
    end

    columns do
      ['new', 'updated'].each do |which|
        column do
          panel "#{which.capitalize} Collections" do
            insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, data[:"#{which}_collections"] do
              column :identifier do |collection|
                link_to collection.identifier, Rails.application.routes.url_helpers.collection_path(collection) # Have to call the full path here as activeadmin has a collection_path
              end
              column :title
            end
          end
        end
      end
    end

    columns do
      ['new', 'updated'].each do |which|
        column do
          panel "#{which.capitalize} Items" do
            insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, data[:"#{which}_items"] do
              column :full_identifier do |item|
                link_to item.full_identifier, [item.collection, item]
              end
              column :title
            end
          end
        end
      end
    end

    columns do
      ['new', 'updated'].each do |which|
        column do
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

    columns do
      column do
        panel 'File Type Metrics' do
          stuff = Essence.where('created_at <= ?', date.end_of_month).select('mimetype, COUNT(*) as files, SUM(size) as bytes, SUM(duration) as duration').group(:mimetype).order('files desc')
          insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, stuff do
            column :type
            column :files
            column :bytes, :as => 'Size' do |thing|
              number_to_human_size thing.bytes
            end
            column :duration do |thing|
              number_to_human_duration thing.duration
            end
          end

        end
      end

      column do
        panel 'Collection Metrics' do
          insert_tag ActiveAdmin::Views::IndexAsTable::IndexTableFor, Collection.all do
            column :identifier
            column :items do |collection|
              collection.items.count
            end

            column :files do |collection|
              Essence.where('created_at <= ?', date.end_of_month).where(:item_id => collection.items.map(&:id)).count
            end
            column :bytes, :as => 'Size' do |collection|
              number_to_human_size Essence.where('created_at <= ?', date.end_of_month).where(:item_id => collection.items.map(&:id)).sum(:size)
            end
            column :duration do |collection|
              number_to_human_duration Essence.where('created_at <= ?', date.end_of_month).where(:item_id => collection.items.map(&:id)).sum(:duration)
            end
          end
        end
      end
    end
  end

end
