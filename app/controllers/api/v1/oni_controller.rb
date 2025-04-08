module Api
  module V1
    class OniController < ApplicationController
      def entities
        query = Oni::ObjectsValidator.new(params)

        unless query.valid?
          render json: { errors: query.errors.full_messages }, status: :unprocessable_entity

          return
        end

        sort = query.sort === 'id' ? 'entity_id' : query.sort

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

        if check_for_essence
          # NOTE: Hard code the format as rails pick up the extension in the id
          render 'object_meta_essence', formats: [:json]

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
        puts '🪚 🟩'

        raise ActiveRecord::RecordNotFound unless check_for_item
        puts '🪚 ⭐'

        essence = @data.essences.find_by(filename: params[:path])
        puts '🪚 🔲'

        raise ActiveRecord::RecordNotFound unless essence
        puts '🪚 ⭕'

        location = Nabu::Catalog.instance.essence_url(essence, as_attachment:, filename:)
        puts '🪚 🔵'
        raise ActionController::RoutingError, 'Essence file not found' unless location
        puts '🪚 💜'

        redirect_to location, allow_other_host: true
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

        aggs = %i[memberOf root languages countries collector_name]

        @search = Searchkick.search(
          query.query,
          models: [Collection, Item],
          model_includes: { Collection => [:languages, :access_condition], Item => [:content_languages, :access_condition, :collection] },
          limit: query.limit,
          offset: query.offset,
          order:, where:,
          aggs:,
          body_options: { track_total_hits: true },
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
