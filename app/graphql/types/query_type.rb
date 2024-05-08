module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    include HasSearch
    self.search_model = Item

    # So we can use HasSearch
    attr_reader :params, :current_user

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :collection, CollectionType, 'Find a collection by identifier. e.g. NT1' do
      argument :identifier, ID
    end

    # Then provide an implementation:
    def collection(identifier:)
      Collection.find_by(identifier:)
    end

    field :item, ItemType, 'Find an item by full identifier. e.g. NT1-009' do
      argument :full_identifier, ID
    end

    # Then provide an implementation:
    def item(full_identifier:)
      collection_identifier, item_identifier = full_identifier.split('-')
      collection = Collection.find_by(identifier: collection_identifier)
      collection.items.find_by(identifier: item_identifier)
    end

    field :item_bwf_csv, ItemBwfCsvType, 'Get the BWF CSV for an item' do
      argument :full_identifier, ID
      argument :filename, String
    end
    def item_bwf_csv(full_identifier:, filename:)
      raise(GraphQL::ExecutionError, 'Not authorised') unless context[:admin_authenticated]

      collection_identifier, item_identifier = full_identifier.split('-')
      collection = Collection.find_by(identifier: collection_identifier)
      raise(GraphQL::ExecutionError, 'Not found') unless collection

      item = collection.items.find_by(identifier: item_identifier)
      raise(GraphQL::ExecutionError, 'Not found') unless item

      desc = [
        '# Notes',
        '',
        "Reference: https://catalog.paradisec.org.au/repository/#{collection.identifier}/#{item.identifier}",
      ]

      unless item.subject_languages.empty?
        desc << "Language: #{item.subject_languages.first.name}\" #{item.subject_languages.first.code}"
      end

      desc << "Country: #{item.countries.first.code}" unless item.countries.empty?
      desc << "Description: #{item.description}"

      bwf = {
        'FileName' => filename,
        'Description' => desc.join('\n').truncate(256),
        'Originator' => item.collector_name,
        'OriginationDate' => item.originated_on,
        'BextVersion' => 1,
        'CodingHistory' => 'A=PCM,F=96000,W=24,M=stereo,T=Paragest Pipeline'
        # 'TBA' => @item.ingest_notes
      }

      csv = CSV.generate(headers: true) do |c|
        c << bwf.keys
        c << bwf.values
      end

      {
        full_identifier: item.full_identifier,
        collection_identifier: collection.identifier,
        item_identifier: item.identifier,
        csv:,
        created_at: item.created_at,
        updated_at: item.updated_at
      }
    end

    field :item_id3, ItemId3Type, 'Get the ID3 XML for an item' do
      argument :full_identifier, ID
    end
    def item_id3(full_identifier:)
      raise(GraphQL::ExecutionError, 'Not authorised') unless context[:admin_authenticated]

      collection_identifier, item_identifier = full_identifier.split('-')
      collection = Collection.find_by(identifier: collection_identifier)
      raise(GraphQL::ExecutionError, 'Not found') unless collection

      item = collection.items.find_by(identifier: item_identifier)
      raise(GraphQL::ExecutionError, 'Not found') unless item

      warden = Warden::Proxy.new({}, Warden::Manager.new({})).tap do |i|
        i.set_user(context[:current_user], scope: :user)
      end
      item_renderer = ItemsController.renderer.new('warden' => warden)

      txt = item_renderer.render(:item_id3, formats: [:txt], assigns: { item: })

      {
        full_identifier: item.full_identifier,
        collection_identifier: collection.identifier,
        item_identifier: item.identifier,
        txt:,
        created_at: item.created_at,
        updated_at: item.updated_at
      }
    end

    field :items, Types::ItemResultType, null: true do
      argument :limit, Integer, default_value: 10, required: false
      argument :page, Integer, default_value: 1, required: false
      # argument :sort_order, String, default_value: :full_identifier, required: false, camelize: false
      argument :title, String, required: false
      argument :identifier, String, required: false
      argument :full_identifier, String, required: false, camelize: false
      argument :collection_identifier, String, required: false, camelize: false
      argument :collector_name, String, required: false, camelize: false
      argument :university_name, String, required: false, camelize: false
      argument :operator_name, String, required: false, camelize: false
      argument :discourse_type_name, String, required: false, camelize: false
      argument :description, String, required: false
      argument :language, String, required: false
      argument :dialect, String, required: false
      argument :region, String, required: false
      argument :access_narrative, String, required: false, camelize: false
      argument :tracking, String, required: false
      argument :ingest_notes, String, required: false, camelize: false
      argument :born_digital, Boolean, required: false, camelize: false
      argument :originated_on, String, required: false, camelize: false
      argument :essences_count, Integer, required: false, camelize: false
      argument :id, ID, required: false
      argument :access_class, String, required: false, camelize: false
      argument :access_condition_name, String, required: false, camelize: false
      argument :original_media, String, required: false, camelize: false
      argument :received_on, String, required: false, camelize: false
      argument :digitised_on, String, required: false, camelize: false
      argument :originated_on_narrative, String, required: false, camelize: false
      argument :doi, String, required: false
      argument :private, Boolean, required: false
    end

    def items(**args)
      @params = {
        # 500 seems to be the hard limit without server timing out
        # this is hard to optimise as it's more on Ruby memory/object allocation not db query optimisation
        per_page: [args[:limit], 500].min
      }.merge(args.to_h).symbolize_keys
      @current_user = context[:current_user]

      search = build_advanced_search
      ItemResult.new(
        search.total_count,
        search.next_page,
        search
      )
    end

    field :essence, EssenceType, 'Find a collection by identifier. e.g. NT1' do
      argument :full_identifier, ID
      argument :filename, String
    end

    def essence(full_identifier:, filename:)
      collection_identifier, item_identifier = full_identifier.split('-')
      collection = Collection.find_by(identifier: collection_identifier)
      item = collection.items.find_by(identifier: item_identifier)

      item.essences.find_by(filename:)
    end

    field :user_by_unikey, EmailUserType, 'Find a user by their unikey' do
      argument :unikey, String
    end

    def user_by_unikey(unikey:)
      User.find_by(unikey:)
    end
  end
end
