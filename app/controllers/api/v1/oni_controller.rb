module Api
  module V1
    class OniController < ApiController
      skip_before_action :enforce_terms_acceptance, only: %i[capabilities entities entity rocrate search]

      rescue_from ActiveRecord::RecordNotFound do |exception|
        message = exception.message == 'ActiveRecord::RecordNotFound' ? 'The requested entity was not found' : exception.message
        render_api_error('NOT_FOUND', message, :not_found)
      end

      rescue_from CanCan::AccessDenied do
        if current_user
          render_api_error('FORBIDDEN', 'You do not have permission to access this resource', :forbidden)
        else
          render_api_error('UNAUTHORIZED', 'Authentication is required to access this resource', :unauthorized)
        end
      end

      # Cross-index search spans the Collection, Item and Essence indices. A field can only be
      # sorted on if it is mapped in ALL three indices; sorting on a field missing from any index
      # raises an OpenSearch query_shard_exception (HTTP 500). We map each user-facing sort value
      # to an index field present everywhere: title/name sort on title_sort (Essences have no
      # title, so their title_sort falls back to the filename) and id sorts on full_identifier_sort
      # (both number-aware downcased keys); originated_on/created_at/updated_at sort on their date
      # fields. Anything else (relevance) falls back to _score.
      # One source of truth for search highlight markup: the top-level highlight and the nested
      # segment inner-hit highlights must render identically for the frontend <mark> styling.
      HIGHLIGHT_TAG = '<mark class="font-bold">'
      HIGHLIGHT_END_TAG = '</mark>'

      SEARCH_SORT_FIELDS = {
        'title' => 'title_sort',
        'name' => 'title_sort',
        'id' => 'full_identifier_sort',
        'originated_on' => 'originated_on',
        'created_at' => 'created_at',
        'updated_at' => 'updated_at'
      }.freeze

      def capabilities
      end

      def entities # rubocop:disable Metrics/MethodLength
        query = Oni::ObjectsValidator.new(params)

        unless query.valid?
          render_validation_error(query)

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
            render_api_error('VALIDATION_ERROR', 'Invalid memberOf parameter', :bad_request)
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
          render_api_error('VALIDATION_ERROR', 'id is required', :bad_request)

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
          render_api_error('VALIDATION_ERROR', 'id is required', :bad_request)

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
          render_validation_error(query)

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
            render_api_error('VALIDATION_ERROR', 'Invalid memberOf parameter', :bad_request)
            return
          end

          files = files.where(member_of: md[1].sub('/', '-'))
        end

        @total = files.count

        # Every row here is an Essence entity. The view walks essence.item and essence.collection
        # (delegated to item.collection) and calls can?(:read, essence), which checks the item's
        # access_condition plus item/collection permission grants. Preload all of it to avoid the
        # per-essence item/collection N+1 (NABU-MZ) and the latent permission-check N+1.
        @entities = files
          .order("#{sort} #{query.order}")
          .offset(query.offset)
          .limit(query.limit)
          .includes(entity: { item: [:access_condition, :item_permissions, { collection: :collection_permissions }] })
          .load
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
          render_api_error('FORBIDDEN', 'This file is archived and can only be accessed by admins', :forbidden)

          return
        end

        location = Nabu::Catalog.instance.essence_url(@data, as_attachment:, filename:)
        raise ActiveRecord::RecordNotFound, 'Essence file not found' unless location

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
          render_validation_error(query)

          return
        end

        @essence_terms_required = essence_terms_required?

        sort_field = SEARCH_SORT_FIELDS.fetch(query.sort, '_score')
        order = { sort_field => query.order }

        filters = transform_filters(query.filters)

        perms = []
        unless current_user&.admin?
          perms << { private: false }
          # Collection, Item and Essence documents all carry a single deduped access_user_ids union
          # (the full read-visibility set), so one clause covers every entity type in this cross-index
          # search. Mirrors HasSearch#visibility_clauses.
          perms << { access_user_ids: current_user.id } if current_user
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
          highlight: { tag: HIGHLIGHT_TAG }
        }

        if query.search_type == 'advanced'
          @search = Searchkick.search('*', **params) do |payload|
            processed_query = query.query.gsub(/ *:/, '.analyzed:').gsub('name.analyzed:', 'title.analyzed:')
            payload[:query][:bool][:must] = with_segments_clause(
              { query_string: { query: processed_query } },
              query_string: { query: processed_query, default_field: 'segments.text.analyzed' }
            )
          end
        else
          @search = Searchkick.search(query.query, **params) do |payload|
            next if query.query == '*'

            payload[:query][:bool][:must] = with_segments_clause(
              payload[:query][:bool][:must],
              match: { 'segments.text' => { query: query.query, operator: 'and' } }
            )
          end
          @search = @search.indices_boost(Collection => 10, Item => 5, Essence => 1)
        end
      end

      private

      # Extracted content for structured essences (PDF pages, ELAN annotations) lives in the
      # nested segments field, out of reach of the top-level text query, so segment matches need
      # their own nested clause OR-ed alongside it. ignore_unmapped keeps the Collection/Item legs
      # of the cross-index search working (only Essence maps segments), and inner_hits surfaces
      # the top matching segments - locations plus highlights - for searchExtra.segments.
      def with_segments_clause(text_clause, segment_query)
        {
          bool: {
            should: [
              text_clause,
              {
                nested: {
                  path: 'segments',
                  ignore_unmapped: true,
                  score_mode: 'max',
                  query: segment_query,
                  inner_hits: {
                    size: 5,
                    _source: %w[segments.type segments.page segments.tier segments.start_ms segments.end_ms],
                    highlight: {
                      pre_tags: [HIGHLIGHT_TAG],
                      post_tags: [HIGHLIGHT_END_TAG],
                      fields: { 'segments.text' => {}, 'segments.text.analyzed' => {} }
                    }
                  }
                }
              }
            ],
            minimum_should_match: 1
          }
        }
      end

      # Overrides ApiController's version so the 403 uses the spec's error envelope.
      def enforce_terms_acceptance
        return unless current_user
        return if current_user.admin? || current_user.contact_only? || current_user.terms_accepted?

        render_api_error('FORBIDDEN', 'You must accept the terms and conditions', :forbidden)
      end

      def essence_terms_required?
        return false unless current_user
        return false if current_user.admin? || current_user.terms_accepted?

        true
      end

      def transform_filters(filters)
        f = filters.dup

        if f['entity_type'].is_a?(Array)
          f['entity_type'] = f['entity_type'].map { |v| Oni::EntityType.normalise(v) }
        end

        originated_on = f.delete('originatedOn')
        # The spec's FilterRange object maps to a single inclusive range; the legacy
        # 'A TO B' string array (still sent by Oni's date facet) can carry several
        # disjoint year ranges, so those become an _or of ranges.
        case originated_on
        when Hash
          range = {}
          range[:gte] = originated_on['gte'] if originated_on.key?('gte')
          range[:lte] = originated_on['lte'] if originated_on.key?('lte')
          f[:originated_on] = range
        when Array
          ranges = originated_on.filter_map do |range_string|
            parts = range_string.split(' TO ')
            next nil if parts.length != 2

            { gte: parts[0].strip, lte: parts[1].strip }
          end
          f[:_or] = ranges.map { |range| { originated_on: range } }
        end

        f
      end

      def render_validation_error(query)
        render_api_error('VALIDATION_ERROR', query.errors.full_messages.join('; '), :bad_request)
      end

      def render_api_error(code, message, status)
        render json: { error: { code:, message:, requestId: request.request_id } }, status:
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
