module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :items, Types::ItemResultType, null: true do
      argument :limit, Integer, default_value: 10, required: false
      argument :page, Integer, default_value: 1, required: false
      # argument :sort_order, String, default_value: :full_identifier, required: false
      argument :title, String, required: false
      argument :identifier, String, required: false
      argument :full_identifier, String, required: false
      argument :collection_identifier, String, required: false
      argument :collector_name, String, required: false
      argument :university_name, String, required: false
      argument :operator_name, String, required: false
      argument :discourse_type_name, String, required: false
      argument :description, String, required: false
      argument :language, String, required: false
      argument :dialect, String, required: false
      argument :region, String, required: false
      argument :access_narrative, String, required: false
      argument :tracking, String, required: false
      argument :ingest_notes, String, required: false
      argument :born_digital, Boolean, required: false
      argument :originated_on, String, required: false
      argument :essences_count, Integer, required: false
      argument :id, ID, required: false
      argument :access_class, String, required: false
      argument :access_condition_name, String, required: false
      argument :original_media, String, required: false
      argument :received_on, String, required: false
      argument :digitised_on, String, required: false
      argument :originated_on_narrative, String, required: false
      argument :doi, String, required: false
      argument :private, Boolean, required: false
    end

    def items(**args)
      search_params = {
        # 500 seems to be the hard limit without server timing out
        # this is hard to optimise as it's more on Ruby memory/object allocation not db query optimisation
        per_page: args[:limit] > 500 ? 500 : args[:limit]
      }.merge(args.to_h).symbolize_keys

      search = ItemSearchService.build_advanced_search(search_params, context[:current_user])
      results = search.results
      ItemResult.new(
        search.total,
        results.next_page,
        results
      )
    end

  end
end
