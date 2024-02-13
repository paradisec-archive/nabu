module Api
  module V1
    class OniController < ApplicationController
      def objects
        limit = (params[:limit] || 1_000_000).to_i # FIXME: Better way for all record
        offset = (params[:offset] || 0).to_i
        conforms_to = params[:conformsTo]

        collection_label = Arel::Nodes::SqlLiteral.new("'collection'")
        item_label = Arel::Nodes::SqlLiteral.new("'item'")

        collections_table = Collection.where(private: false).arel_table
        items_table = Item.where(private: false).arel_table

        collections_query = collections_table.where(collections_table[:private].eq(false))
        items_query = items_table.project(:id, :created_at, item_label.as('type')).where(items_table[:private].eq(false))

        if params[:memberOf]
          md = params[:memberOf].match(repository_collection_url(:collection_identifier => '(.*)'))
          unless md
            render json: { error: 'Invalid memberOf parameter' }, status: :bad_request
            return
          end

          collections_query = collections_query.where(collections_table[:identifier].eq(md[1])).project(:id)
          combined_query = items_query.where(items_table[:collection_id].in(collections_query))
        else
          collections_query = collections_query.project(:id, :created_at, collection_label.as('type'))
          combined_query = case conforms_to
                           when 'https://purl.archive.org/language-data-commons/profile#Collection'
                             collections_query
                           when 'https://purl.archive.org/language-data-commons/profile#Item'
                             items_query
                           else
                             collections_query.union(items_query)
                           end
        end

        final_query = Arel::SelectManager.new(Arel::Table.engine)
        final_query.from(combined_query.as('combined')).project(Arel.star).order('created_at ASC').skip(offset).take(limit)

        ids = ActiveRecord::Base.connection.select_all(final_query.to_sql)

        collection_ids = ids.select { |id| id['type'] == 'collection' }.pluck('id')
        item_ids = ids.select { |id| id['type'] == 'item' }.pluck('id')

        collections = Collection.where(id: collection_ids)
        items = Item.where(id: item_ids)

        @data = ids.map do |id|
          if id['type'] == 'collection'
            collections.find { |c| c.id == id['id'] }
          else
            items.find { |i| i.id == id['id'] }
          end
        end
      end

      def object
        unless params[:id]
          render json: { error: 'id is required' }, status: :bad_request

          return
        end

        md = params[:id].match(repository_item_url(collection_identifier: '(.*)', item_identifier: '(.*)'))
        if md
          @collection = Collection.find_by(identifier: md[1])
          @data = @collection.items.find_by(identifier: md[2])
        else
          md = params[:id].match(repository_collection_url(collection_identifier: '(.*)'))
          unless md
            render json: { error: 'Invalid id parameter' }, status: :bad_request
            return
          end
          @data = Collection.find_by(identifier: md[1])
        end
      end

      def object_meta
        unless params[:id]
          render json: { error: 'id is required' }, status: :bad_request

          return
        end

        md = params[:id].match(repository_item_url(collection_identifier: '(.*)', item_identifier: '(.*)'))
        if md
          @collection = Collection.find_by(identifier: md[1])
          @data = @collection.items.find_by(identifier: md[2])
          @is_item = true
        else
          md = params[:id].match(repository_collection_url(collection_identifier: '(.*)'))
          unless md
            render json: { error: 'Invalid id parameter' }, status: :bad_request
            return
          end
          @data = Collection.find_by(identifier: md[1])
          @is_item = false
        end
      end
    end
  end
end
