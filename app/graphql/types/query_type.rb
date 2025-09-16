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

    def collection(identifier:)
      c = Collection.find_by!(identifier:)

      authorize! :read, c

      c
    end

    field :item, ItemType, 'Find an item by full identifier. e.g. NT1-009' do
      argument :full_identifier, ID
    end

    def item(full_identifier:)
      collection_identifier, item_identifier = full_identifier.split('-')

      c = Collection.find_by!(identifier: collection_identifier)
      authorize! :read, c

      c.items.accessible_by(current_ability).find_by!(identifier: item_identifier)
    end

    field :item_bwf_csv, ItemBwfCsvType, 'Get the BWF CSV for an item' do
      argument :full_identifier, ID
      argument :filename, String
    end
    def item_bwf_csv(full_identifier:, filename:)
      collection_identifier, item_identifier = full_identifier.split('-')

      c = Collection.find_by!(identifier: collection_identifier)
      authorize! :read, c

      i = c.items.accessible_by(current_ability).find_by!(identifier: item_identifier)
      authorize! :metadata, i

      desc = [
        '# Notes',
        '',
        "Reference: https://catalog.paradisec.org.au/repository/#{c.identifier}/#{i.identifier}"
      ]

      desc << "Language: #{i.subject_languages.first.name}\" #{i.subject_languages.first.code}" unless i.subject_languages.empty?

      desc << "Country: #{i.countries.first.code}" unless i.countries.empty?
      desc << "Description: #{i.description}"

      bwf = {
        'FileName' => filename,
        'Description' => desc.join('\n').truncate(240),
        'Originator' => i.collector_name,
        'OriginationDate' => i.originated_on,
        'BextVersion' => 1,
        'CodingHistory' => 'A=PCM,F=96000,W=24,M=stereo,T=Paragest Pipeline'
        # 'TBA' => @i.ingest_notes
      }

      csv = CSV.generate(headers: true) do |c|
        c << bwf.keys
        c << bwf.values
      end

      {
        full_identifier: i.full_identifier,
        collection_identifier: c.identifier,
        item_identifier: i.identifier,
        csv:,
        created_at: i.created_at,
        updated_at: i.updated_at
      }
    end

    field :item_id3, ItemId3Type, 'Get the ID3 XML for an item' do
      argument :full_identifier, ID
    end
    def item_id3(full_identifier:)
      collection_identifier, item_identifier = full_identifier.split('-')

      c = Collection.find_by!(identifier: collection_identifier)
      authorize! :read, c

      i = c.items.accessible_by(current_ability).find_by!(identifier: item_identifier)
      authorize! :metadata, i

      warden = Warden::Proxy.new({}, Warden::Manager.new({})).tap do |i|
        i.set_user(context[:current_user], scope: :user)
      end
      item_renderer = ItemsController.renderer.new(
        warden: warden,
        http_host: 'catalog.paradisec.org.au',
        https: true
      )

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

      c = Collection.find_by!(identifier: collection_identifier)
      authorize! :read, c

      i = c.items.accessible_by(current_ability).find_by!(identifier: item_identifier)
      authorize! :metadata, i

      i.essences.accessible_by(current_ability).find_by!(filename:)
    end

    field :user_by_unikey, EmailUserType, 'Find a user by their unikey' do
      argument :unikey, String
    end

    def user_by_unikey(unikey:)
      u = User.find_by!(unikey:)
      authorize! :read, u

      { id: u.id, unikey: u.unikey, firstName: u.firstName, lastName: u.lastName, email: u.email }
    end
  end
end
