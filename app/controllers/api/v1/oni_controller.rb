module Api
  module V1
    class OniController < ApplicationController
      def objects
        limit = (params[:limit] || 5_000).to_i # FIXME: Better way for all record
        offset = (params[:offset] || 0).to_i
        sortBy = params[:sortBy] || 'identifier'
        unless %w[identifier title created_at].include?(sortBy)
          orderBy = 'identifier'
        end
        sortDirection = (params[:sortDirection] || '').upcase === 'DESC' ? 'DESC' : 'ASC'
        conforms_to = params[:conformsTo]

        collections_table = Collection.where(private: false).arel_table
        items_table = Item.where(private: false).arel_table

        collection_label = Arel::Nodes::SqlLiteral.new("'collection'")
        item_label = Arel::Nodes::SqlLiteral.new("'item'")

        item_identifier = Arel::Nodes::NamedFunction.new(
          'CONCAT',
          [collections_table[:identifier], Arel::Nodes.build_quoted('-'), items_table[:identifier]]
        ).as('identifier')

        collections_query = collections_table.where(collections_table[:private].eq(false))
        items_query = items_table
          .join(collections_table).on(items_table[:collection_id].eq(collections_table[:id]))
          .project(items_table[:id], items_table[:created_at], item_identifier, items_table[:title], item_label.as('type'))
          .where(items_table[:private].eq(false))

        if params[:memberOf]
          md = params[:memberOf].match(repository_collection_url(collection_identifier: '(.*)'))
          unless md
            render json: { error: 'Invalid memberOf parameter' }, status: :bad_request
            return
          end

          collections_query = collections_query.where(collections_table[:identifier].eq(md[1])).project(:id)
          combined_query = items_query.where(items_table[:collection_id].in(collections_query))
        else
          collections_query = collections_query.project(:id, :created_at, :identifier, :title, collection_label.as('type'))
          combined_query = case conforms_to
          when 'https://purl.archive.org/language-data-commons/profile#Collection'
            collections_query
          when 'https://purl.archive.org/language-data-commons/profile#Item'
            items_query
          else
            collections_query.union(items_query)
          end
        end

        # Count query to get the total number of records
        count_query = Arel::SelectManager.new(Arel::Table.engine)
        count_query.from(combined_query.as('combined')).project(Arel.star.count.as('total_count'))

        total_count_result = ActiveRecord::Base.connection.select_all(count_query.to_sql)
        @total = total_count_result.first['total_count']

        # Final query with limit and offset
        final_query = Arel::SelectManager.new(Arel::Table.engine)
        final_query.from(combined_query.as('combined')).project(Arel.star).order("#{sortBy} #{sortDirection}").skip(offset).take(limit)

        ids = ActiveRecord::Base.connection.select_all(final_query.to_sql)

        collection_ids = ids.select { |id| id['type'] == 'collection' }.pluck('id')
        item_ids = ids.select { |id| id['type'] == 'item' }.pluck('id')

        collections = Collection.where(id: collection_ids).includes(:access_condition)
        items = Item.where(id: item_ids).includes(:collection, :access_condition)

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
          @data = @collection.items.includes(:content_languages, :subject_languages, item_agents: %i[agent_role user]).find_by(identifier: md[2])
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

        @admin_rocrate = false

        raise ActiveRecord::RecordNotFound unless @data
      end
    end
  end
end
