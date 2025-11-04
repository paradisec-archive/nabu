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
        ).or(
          Entity.where(
            entity_type: 'Essence',
            entity_id: Essence.accessible_by(current_ability)
          )
        )

        if query.member_of
          md = query.member_of.match(repository_collection_url(collection_identifier: '(.*)'))
          entity_type = 'Item' if md

          unless entity_type
            md = query.member_of.match(repository_collection_url(collection_identifier: '(.*)', item_identifier: '(.*)'))
            entity_type = 'Essence' if md
          end

          unless md
            render json: { error: 'Invalid memberOf parameter' }, status: :bad_request
            return
          end

          entities = entities.where(member_of: md[1], entity_type:)
        end

        case query.entity_type
        when 'http://pcdm.org/models#Collection'
          if query.member_of
            # NOTE: We don't have collections of collections so we craft a query that will return nothing
            entities = Entity.none
          else
            entities = entities.where(entity_type: 'Collection')
          end
        when 'http://pcdm.org/models#Object'
          entities = entities.where(entity_type: 'Item')
        when 'http://schema.org/MediaObject'
          entities = entities.where(entity_type: 'File')
        else
          # Do nothing
        end

        @total = entities.count

        @entities = entities.order("#{sort} #{query.order}").offset(query.offset).limit(query.limit).includes(entity: [:access_condition, :languages, :content_languages, :collection, :essences]).load
      end

      def entity
        unless params[:id]
          render json: { error: 'id is required' }, status: :bad_request

          return
        end

        if check_for_essence
          @entity = @data.entity
        elsif check_for_item
          @entity = @data.entity
        elsif check_for_collection
          @entity = @data.entity
        else
          raise ActiveRecord::RecordNotFound
        end
      end

      def rocrate
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

        as_attachment = params[:disposition] == 'attachment'
        filename = params[:filename]

        ## Only items have files
        raise ActiveRecord::RecordNotFound unless check_for_essence

        location = Nabu::Catalog.instance.essence_url(@data, as_attachment:, filename:)
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
        f = transform_filters(query.filters)
        where.merge!(f)

        if query.bounding_box
          where[:location] = {
            top_right: { lat: query.bounding_box[:topRight][:lat], lon: query.bounding_box[:topRight][:lng] },
            bottom_left: { lat: query.bounding_box[:bottomLeft][:lat], lon: query.bounding_box[:bottomLeft][:lng] }
          }
        end

        aggs = {
          collection_title: {},
          access_condition_name: {},
          languages: { limit: 2000 },
          countries: {},
          collector_name: {},
          encodingFormat: {},
          rootCollection: {},
          originatedOn: { date_histogram: { field: 'originated_on', calendar_interval: 'year', format: 'yyyy', min_doc_count: 1 } }
        }

        body_options = { track_total_hits: true }
        if query.geohash_precision
          body_options[:aggs] = {
            location: { geohash_grid: { precision: query.geohash_precision, field: 'location' } }
          }
        end

        #  TODO use new search DSL
        params = {
          models: [Collection, Item],
          model_includes: { Collection => [:languages, :access_condition, :entity, items: :essences], Item => [:content_languages, :access_condition, :collection, :entity] },
          limit: query.limit,
          offset: query.offset,
          order:,
          where:,
          aggs:,
          body_options:,
          highlight: { tag: '<mark class="font-bold">' }
        }

        if query.search_type == 'advanced'
          @search = Searchkick.search('*', **params) do |payload|
            processed_query = query.query.gsub(/ *:/, '.analyzed:').gsub('name.analyzed:', 'title.analyzed:')
            payload[:query][:bool][:must] =  { query_string: { query: processed_query  } }
          end
        else
          @search = Searchkick.search(query.query, **params)
        end
      end

      private
      def transform_filters(filters)
        f = filters.to_h.to_h

        return f unless f['originatedOn']

        ranges = parse_originated_on_ranges(f['originatedOn'])
        f.delete('originatedOn')
        f[:_or] = ranges.map { |range| { originated_on: range } }

        f
      end

      def parse_originated_on_ranges(originated_on_array)
        originated_on_array.map do |range_string|
          unless range_string.match?(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z TO \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/)
            errors.add(:filters, "originatedOn range '#{range_string}' must be in format 'YYYY-MM-DDTHH:MM:SS.sssZ TO YYYY-MM-DDTHH:MM:SS.sssZ'")
          end

          # Parse format: 'YYYY-MM-DDTHH:MM:SS.sssZ TO YYYY-MM-DDTHH:MM:SS.sssZ'
          parts = range_string.split(' TO ')
          next nil if parts.length != 2

          { gte: parts[0].strip, lte: parts[1].strip }
        end.compact
      end

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
