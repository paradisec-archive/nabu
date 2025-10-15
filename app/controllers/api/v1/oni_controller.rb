module Api
  module V1
    class OniController < ApiController
      def entities
        query = Oni::ObjectsValidator.new(params)

        unless query.valid?
          render json: { errors: query.errors.full_messages }, status: :unprocessable_entity

          return
        end

        sort = case query.sort
        when 'id' then 'entity_id'
        when 'name' then 'title'
        else query.sort
        end

        entities = Entity.where(
          entity_type: 'Collection',
          entity_id: Collection.accessible_by(current_ability)
        ).or(
          Entity.where(
            entity_type: 'Item',
            entity_id: Item.accessible_by(current_ability)
          )
        )

        if query.member_of
          md = query.member_of.match(repository_collection_url(collection_identifier: '(.*)'))
          unless md
            render json: { error: 'Invalid memberOf parameter' }, status: :bad_request
            return
          end

          entities = entities.where(identifier: md[1])
        end

        case query.conforms_to
        when ['https://w3id.org/ldac/profile#Collection']
          if query.member_of
            # NOTE: We don't have collections of collections so we craft a query that will return nothing
            entities = Entity.none
          else
            entities = entities.where(entity_type: 'Collection')
          end
        when ['https://w3id.org/ldac/profile#Object']
          entities = entities.where(entity_type: 'Item')
        else
          # Do nothing
        end

        @total = entities.count

        entities = entities.order("#{sort} #{query.order}").offset(query.offset).limit(query.limit).includes(entity: [:access_condition, :languages, :content_languages]).load

        collection_ids = entities.select { |id| id.entity_type == 'Collection' }.map(&:entity_id)
        item_ids = entities.select { |id| id.entity_type == 'Item' }.map(&:entity_id)

        collection_mimetypes = Essence.joins(item: :collection).where(item: { collection_id: collection_ids }).distinct.pluck(:mimetype)
        item_mimetypes = Essence.joins(:item).where(item_id: item_ids).distinct.pluck(:mimetype)
        @mime_types = collection_mimetypes.concat(item_mimetypes).uniq

        @entities = entities.map(&:entity)
      end

      def entity
        unless params[:id]
          render json: { error: 'id is required' }, status: :bad_request

          return
        end

        @admin_rocrate = false

        if check_for_item
          @entity = @data
        elsif check_for_collection
          @entity = @data
        else
          raise ActiveRecord::RecordNotFound
        end
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

        # Special treatment for ro-crate-metadata.json
        if params[:path] === 'ro-crate-metadata.json'
          @admin_rocrate = false

          if check_for_item
            render 'object_meta_item'

            return
          end

          if check_for_collection
            render 'object_meta_collection'

            return
          end
        end

        ## Only items have files
        raise ActiveRecord::RecordNotFound unless check_for_item

        essence = @data.essences.accessible_by(current_ability).find_by(filename: params[:path])
        raise ActiveRecord::RecordNotFound unless essence

        location = Nabu::Catalog.instance.essence_url(essence, as_attachment:, filename:)
        raise ActionController::RoutingError, 'Essence file not found' unless location

        if params[:noRedirect] === 'true'
          render json: { location: }
        else
          redirect_to location, allow_other_host: true
        end
      end

      def search
        query = Oni::SearchValidator.new(params)

        unless query.valid?
          render json: { errors: query.errors.full_messages }, status: :unprocessable_entity

          return
        end

        order = {}
        order[query.sort === 'relevance' ? '_score' : query.sort] = query.order

        where = {
          private: false
        }
        where.merge!(query.filters)

        if query.bounding_box
          where[:location] = {
            top_right: { lat: query.bounding_box[:topRight][:lat], lon: query.bounding_box[:topRight][:lng] },
            bottom_left: { lat: query.bounding_box[:bottomLeft][:lat], lon: query.bounding_box[:bottomLeft][:lng] }
          }
        end

        aggs = %i[collection_title access_condition_name languages countries collector_name]

        body_options = { track_total_hits: true }
        if query.geohash_precision
          body_options[:aggs] = {
            location: { geohash_grid: { precision: query.geohash_precision, field: 'location' } }
          }
        end

        @search = Searchkick.search(
          query.query,
          models: [Collection, Item],
          model_includes: { Collection => [:languages, :access_condition, items: :essences], Item => [:content_languages, :access_condition, :collection] },
          limit: query.limit,
          offset: query.offset,
          order:, where:,
          aggs:,
          body_options:,
          highlight: { tag: '<mark class="font-bold">' }
        )
      end

      private
      def check_for_essence
        puts repository_essence_url(collection_identifier: '(.*)', item_identifier: '(.*)', essence_filename: '(.*)')

        md = params[:id].match(repository_essence_url(collection_identifier: '(.*)', item_identifier: '(.*)', essence_filename: '(.*)'))
        return false unless md

        @collection = Collection.accessible_by(current_ability).find_by(identifier: md[1])
        return false unless @collection

        @item = @collection.items
          .accessible_by(current_ability)
          .includes(:content_languages, :subject_languages, item_agents: %i[agent_role user]).find_by(identifier: md[2])
        return false unless @item

        @data = @item.essences
          .accessible_by(current_ability)
          .find_by(filename: md[3])

        return false unless @data

        true
      end

      def check_for_item
        md = params[:id].match(repository_item_url(collection_identifier: '(.*)', item_identifier: '(.*)'))
        return false unless md

        @collection = Collection.accessible_by(current_ability).find_by(identifier: md[1])
        return false unless @collection

        @data = @collection.items
          .accessible_by(current_ability)
          .includes(:content_languages, :subject_languages, item_agents: %i[agent_role user]).find_by(identifier: md[2])
        return false unless @data

        true
      end

      def check_for_collection
        md = params[:id].match(repository_collection_url(collection_identifier: '(.*)'))
        return false unless md

        @data = Collection.accessible_by(current_ability).find_by(identifier: md[1])
        return false unless @data

        @is_item = false

        true
      end
    end
  end
end
