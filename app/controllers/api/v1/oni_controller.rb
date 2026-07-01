module Api
  module V1
    class OniController < ApiController
      skip_before_action :enforce_terms_acceptance, only: %i[entities entity rocrate search]

      # Cross-index search spans the Collection, Item and Essence indices. A field can only be
      # sorted on if it is mapped in ALL three indices; sorting on a field missing from any index
      # raises an OpenSearch query_shard_exception (HTTP 500). We map each user-facing sort value
      # to an index field present everywhere: title/name sort on title_sort (Essences have no
      # title, so their title_sort falls back to the filename) and id sorts on full_identifier_sort
      # (both number-aware downcased keys); originated_on/created_at/updated_at sort on their date
      # fields. Anything else (relevance) falls back to _score.
      SEARCH_SORT_FIELDS = {
        'title' => 'title_sort',
        'name' => 'title_sort',
        'id' => 'full_identifier_sort',
        'originated_on' => 'originated_on',
        'created_at' => 'created_at',
        'updated_at' => 'updated_at'
      }.freeze

      def entities # rubocop:disable Metrics/MethodLength
        query = Oni::ObjectsValidator.new(params)

        unless query.valid?
          render json: { errors: query.errors.full_messages }, status: :unprocessable_entity

          return
        end

        sort = case query.sort
        when 'name' then 'title'
        else query.sort
        end

        entities = Entity.accessible_by(current_ability)

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

          entities = entities.where(member_of: md[1].sub('/', '-'), entity_type:)
        end

        internal_type = Oni::EntityType.from_pcdm(query.entity_type)
        if internal_type
          entities = if internal_type == 'Collection' && query.member_of
            # NOTE: We don't have collections of collections so we craft a query that will return nothing
            Entity.none
          else
            entities.where(entity_type: internal_type)
          end
        end

        entities = entities.where.not(entity_type: 'Essence') if essence_terms_required?

        @essence_terms_required = essence_terms_required?

        @total = entities.count

        @entities = entities.offset(query.offset).limit(query.limit).includes(entity: [:access_condition, :languages, :content_languages, :collection, :essences])
        if sort
          @entities = @entities.order("#{sort} #{query.order}")
        end

        @entities = @entities.load

        # Preload associations needed for CanCan permission checks to avoid N+1 queries
        # when the view calls can?(:read, essence) for each entity
        items = @entities.filter_map { |e| e.entity if e.entity_type == 'Item' }
        if items.any?
          ActiveRecord::Associations::Preloader.new(
            records: items,
            associations: [:item_permissions, :access_condition, { collection: :collection_permissions }]
          ).call
        end

        # For Collection entities, the view checks can?(:read, items.first.essences.first)
        # so we need to preload items and their permission associations
        collections = @entities.filter_map { |e| e.entity if e.entity_type == 'Collection' }
        if collections.any?
          ActiveRecord::Associations::Preloader.new(
            records: collections,
            associations: [:collection_permissions, { items: [:essences, :item_permissions, :access_condition] }]
          ).call
        end
      end

      def entity
        unless params[:id]
          render json: { error: 'id is required' }, status: :bad_request

          return
        end

        @essence_terms_required = essence_terms_required?

        if check_for_essence
          raise ActiveRecord::RecordNotFound if essence_terms_required?
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

        @essence_terms_required = essence_terms_required?

        if check_for_essence
          raise ActiveRecord::RecordNotFound if essence_terms_required?
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

      def files
        query = Oni::FilesValidator.new(params)

        unless query.valid?
          render json: { errors: query.errors.full_messages }, status: :unprocessable_entity

          return
        end

        sort = case query.sort
        when 'id' then 'entity_id'
        when 'name' then 'title'
        else query.sort
        end

        files = Entity.accessible_by(current_ability).where(entity_type: 'Essence')

        if query.member_of
          md = query.member_of.match(repository_collection_url(collection_identifier: '(.*)'))

          unless md
            render json: { error: 'Invalid memberOf parameter' }, status: :bad_request
            return
          end

          files = files.where(member_of: md[1].sub('/', '-'))
        end

        @total = files.count

        @entities = files.order("#{sort} #{query.order}").offset(query.offset).limit(query.limit).includes(entity: [:collections, :items, :essences]).load
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

        if !current_user&.admin? && @data.is_archived?
          render json: { error: 'This file is archived and can only be accessed by admins' }, status: :forbidden

          return
        end

        location = Nabu::Catalog.instance.essence_url(@data, as_attachment:, filename:)
        raise ActionController::RoutingError, 'Essence file not found' unless location

        Download.create!(user: current_user, essence: @data) if as_attachment

        if params[:noRedirect] === 'true'
          render json: { location: }
        else
          redirect_to location, allow_other_host: true
        end
      end

      def announcements
        @announcements = AdminMessage.active.order(start_at: :desc)
      end

      def search
        query = Oni::SearchValidator.new(params)

        unless query.valid?
          render json: { errors: query.errors.full_messages }, status: :unprocessable_entity

          return
        end

        @essence_terms_required = essence_terms_required?

        sort_field = SEARCH_SORT_FIELDS.fetch(query.sort, '_score')
        order = { sort_field => query.order }

        filters = transform_filters(query.filters)

        perms = []
        unless current_user&.admin?
          perms << { private: false }
          if current_user
            Collection.search_user_fields.each do |field|
              perms << { field => current_user.id }
            end

            Item.search_user_fields.each do |field|
              perms << { field => current_user.id }
            end

            Essence.search_user_fields.each do |field|
              perms << { field => current_user.id }
            end
          end
        end

        where = {
          _and: [
            filters,
            perms.empty? ? {} : { _or: perms }
          ]
        }

        if query.bounding_box
          where[:location] = {
            top_right: { lat: query.bounding_box[:topRight][:lat], lon: query.bounding_box[:topRight][:lng] },
            bottom_left: { lat: query.bounding_box[:bottomLeft][:lat], lon: query.bounding_box[:bottomLeft][:lng] }
          }
        end

        aggs = {
          collection_title: {},
          access_condition_name: {},
          languages_with_code: { limit: 2000 },
          countries: {},
          collector_name: {},
          encodingFormat: {},
          rootCollection: {},
          originatedOn: { date_histogram: { field: 'originated_on', calendar_interval: 'year', format: 'yyyy', min_doc_count: 1 } },
          entity_type: {},
          full_identifier: {}
        }

        body_options = { track_total_hits: true }
        if query.geohash_precision
          body_options[:aggs] = {
            location: { geohash_grid: { precision: query.geohash_precision, field: 'location' } }
          }
        end

        #  TODO use new search DSL
        params = {
          models: [Collection, Item, Essence],
          model_includes: {
            Collection => [:languages, :access_condition, :entity, items: :essences],
            Item => [:content_languages, :access_condition, :collection, :entity],
            Essence => [{ item: [:collection, :content_languages, :access_condition] }, :entity]
          },
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
          @search = Searchkick.search(query.query, **params).indices_boost(Collection => 10, Item => 5, Essence => 1)
        end
      end

      private

      def essence_terms_required?
        return false unless current_user
        return false if current_user.admin? || current_user.terms_accepted?

        true
      end

      def transform_filters(filters)
        f = filters.to_h.to_h

        if f['entity_type'].is_a?(Array)
          f['entity_type'] = f['entity_type'].map { |v| Oni::EntityType.normalise(v) }
        end

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
        md = params[:id].match(repository_essence_url(collection_identifier: '(.*)', item_identifier: '(.*)', essence_filename: '(.*)'))
        return false unless md

        @collection = Collection.find_by(identifier: md[1])
        return false unless @collection

        @item = @collection.items
          .includes(:content_languages, :subject_languages, item_agents: %i[agent_role user]).find_by(identifier: md[2])
        return false unless @item

        @data = @item.essences.find_by(filename: md[3])

        return false unless @data

        authorize! :read, @data

        true
      end

      def check_for_item
        md = params[:id].match(repository_item_url(collection_identifier: '(.*)', item_identifier: '(.*)'))
        return false unless md

        @collection = Collection.find_by(identifier: md[1])
        return false unless @collection

        @data = @collection.items
          .includes(:content_languages, :subject_languages, item_agents: %i[agent_role user]).find_by(identifier: md[2])
        return false unless @data

        authorize! :read, @data

        true
      end

      def check_for_collection
        md = params[:id].match(repository_collection_url(collection_identifier: '(.*)'))
        return false unless md

        @data = Collection.find_by(identifier: md[1])
        return false unless @data

        authorize! :read, @data

        @is_item = false

        true
      end
    end
  end
end
