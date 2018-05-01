Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :items, Types::ItemResultType do
    argument :limit, types.Int, default_value: 10
    argument :page, types.Int, default_value: 1
    # argument :sort_order, types.String, default_value: :full_identifier
    argument :title, types.String
    argument :identifier, types.String
    argument :full_identifier, types.String
    argument :collection_identifier, types.String
    argument :collector_name, types.String
    argument :university_name, types.String
    argument :operator_name, types.String
    argument :discourse_type_name, types.String
    argument :description, types.String
    argument :language, types.String
    argument :dialect, types.String
    argument :region, types.String
    argument :access_narrative, types.String
    argument :tracking, types.String
    argument :ingest_notes, types.String
    argument :born_digital, types.Boolean
    argument :originated_on, types.String
    argument :essences_count, types.Int
    argument :id, types.ID
    argument :access_class, types.String
    argument :access_condition_name, types.String
    argument :original_media, types.String
    argument :received_on, types.String
    argument :digitised_on, types.String
    argument :originated_on_narrative, types.String
    argument :doi, types.String
    argument :private, types.Boolean

    resolve ->(object, args, ctx) {
      search_params = {
        # 500 seems to be the hard limit without server timing out
        # this is hard to optimise as it's more on Ruby memory/object allocation not db query optimisation
        per_page: args['limit'] > 500 ? 500 : args['limit']
      }.merge(args.to_h).symbolize_keys
      
      search = ItemSearchService.build_advanced_search(search_params, ctx[:current_user])
      results = search.results
      Struct::ItemResult.new(
        search.total,
        results.next_page,
        results
      )
    }
  end
end
