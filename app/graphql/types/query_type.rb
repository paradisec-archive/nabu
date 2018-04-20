ItemResult = Struct.new('ItemResult', :total, :next_page, :results)

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

    resolve ->(object, args, ctx) {
      search_params = {
        title: args['title'],
        identifier: args['identifier'],
        full_identifier: args['full_identifier'],
        collection_identifier: args['collection_identifier'],
        collector_name: args['collector_name'],
        university_name: args['university_name'],
        operator_name: args['operator_name'],
        discourse_type_name: args['discourse_type_name'],
        description: args['description'],
        language: args['language'],
        dialect: args['dialect'],
        region: args['region'],
        access_narrative: args['access_narrative'],
        tracking: args['tracking'],
        ingest_notes: args['ingest_notes'],
        born_digital: args['born_digital'],
        originated_on: args['originated_on'],
        page: args['page'],
        # 500 seems to be the hard limit without server timing out
        # this is hard to optimise as it's more on Ruby memory/object allocation not db query optimisation
        per_page: args['limit'] > 500 ? 500 : args['limit']
      }
      
      search = ItemSearchService.build_advanced_search(search_params, ctx[:current_user])
      results = search.results
      ItemResult.new(
        search.total,
        results.next_page,
        results
      )
    }
  end
end
