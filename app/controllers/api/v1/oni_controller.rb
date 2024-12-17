module Api
  module V1
    class OniController < ApplicationController
      def entities
        query = Oni::ObjectsValidator.new(params)

        render json: { errors: query.errors.full_messages }, status: :unprocessable_entity unless query.valid?

        # TODO: Expand this once we have an authenticated version of this endpoint
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
          .project(items_table[:id], items_table[:created_at], items_table[:updated_at], item_identifier, items_table[:title], item_label.as('type'))
          .where(items_table[:private].eq(false))

        if query.member_of
          md = query.member_of.match(repository_collection_url(collection_identifier: '(.*)'))
          unless md
            render json: { error: 'Invalid memberOf parameter' }, status: :bad_request
            return
          end

          collections_query = collections_query.where(collections_table[:identifier].eq(md[1]))
          items_query = items_query.where(items_table[:collection_id].in(collections_query.clone.project(collections_table[:id])))
        end

        collections_query = collections_query.project(:id, :created_at, :updated_at, :identifier, :title, collection_label.as('type'))

        combined_query = case query.conforms_to
        when ['https://w3id.org/ldac/profile#Collection']
          # A bit hacky but we dont' have colletctions of collections
          if query.member_of
            collections_query.where(collections_table[:identifier].eq('DUMMYsajkdhakshfvksfslkj'))
          else
            collections_query
          end
        when ['https://w3id.org/ldac/profile#Object']
          items_query
        else
            collections_query.union(items_query)
        end

        # Count query to get the total number of records
        count_query = Arel::SelectManager.new(Arel::Table.engine)
        count_query.from(combined_query.as('combined')).project(Arel.star.count.as('total_count'))

        total_count_result = ActiveRecord::Base.connection.select_all(count_query.to_sql)
        @total = total_count_result.first['total_count']

        # Final query with limit and offset
        final_query = Arel::SelectManager.new(Arel::Table.engine)
        final_query.from(combined_query.as('combined')).project(Arel.star).order("#{query.sort} #{query.order}").skip(query.offset).take(query.limit)

        ids = ActiveRecord::Base.connection.select_all(final_query.to_sql)

        collection_ids = ids.select { |id| id['type'] == 'collection' }.pluck('id')
        item_ids = ids.select { |id| id['type'] == 'item' }.pluck('id')

        collection_mimetypes = Essence.joins(item: :collection).where(item: { collection_id: collection_ids }).distinct.pluck(:mimetype)
        item_mimetypes = Essence.joins(:item).where(item_id: item_ids).distinct.pluck(:mimetype)
        @mime_types = collection_mimetypes.concat(item_mimetypes).uniq

        collections = Collection.where(id: collection_ids)
                                .select('collections.*, COUNT(DISTINCT items.id) AS items_count, COUNT(essences.id) AS essences_count')
                                .left_joins(items: :essences)
                                .group('collections.id')
                                .includes(:access_condition, :languages)
        items = Item.where(id: item_ids)
                     .select('items.*, COUNT(essences.id) AS essences_count')
                     .left_joins(:essences)
                     .group('items.id')
                     .includes(:collection, :access_condition, :content_languages)

        @entities = ids.map do |id|
          if id['type'] == 'collection'
            collections.find { |c| c.id == id['id'] }
          else
            items.find { |i| i.id == id['id'] }
          end
        end
      end

      def entity
        unless params[:id]
          render json: { error: 'id is required' }, status: :bad_request

          return
        end

        @admin_rocrate = false

        if check_for_essence
          render 'object_meta_essence'
          return
        end

        if check_for_item
          render 'object_meta_item'
          return
        end

        if check_for_collection
          render 'object_meta_collection'
          return
        end

        raise ActiveRecord::RecordNotFound
      end

      def file
        unless params[:id]
          render json: { error: 'id is required' }, status: :bad_request

          return
        end

        unless params[:path]
          render json: { error: 'path is required' }, status: :bad_request

          return
        end

        as_attachment = params[:disposition] == 'attachment'
        filename = params[:filename]

        raise ActiveRecord::RecordNotFound unless check_for_item

        essence = @data.essences.find_by(filename: params[:path])

        raise ActiveRecord::RecordNotFound unless essence

        location = Nabu::Catalog.instance.essence_url(essence, as_attachment:, filename:)
        raise ActionController::RoutingError, 'Essence file not found' unless location

        redirect_to location, allow_other_host: true
      end

      private
      def check_for_essence
        md = params[:id].match(repository_essence_url(collection_identifier: '(.*)', item_identifier: '(.*)', essence_filename: '(.*)'))
        return false unless md

        @collection = Collection.where(private: false).find_by(identifier: md[1])
        @item = @collection.items
          .where(private: false)
          .includes(:content_languages, :subject_languages, item_agents: %i[agent_role user]).find_by(identifier: md[2])

        @data = @item.essences.find_by(filename: md[3])

        true
      end

      def check_for_item
        md = params[:id].match(repository_item_url(collection_identifier: '(.*)', item_identifier: '(.*)'))
        return false unless md

        @collection = Collection.where(private: false).find_by(identifier: md[1])
        @data = @collection.items
          .where(private: false)
          .includes(:content_languages, :subject_languages, item_agents: %i[agent_role user]).find_by(identifier: md[2])

        true
      end

      def check_for_collection
        md = params[:id].match(repository_collection_url(collection_identifier: '(.*)'))
        return false unless md

        @data = Collection.where(private: false).find_by(identifier: md[1])
        @is_item = false

        true
      end
    end
  end
end
