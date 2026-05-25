RSpec.configure do |config|
   config.before(:suite) do
    Collection.reindex
    Item.reindex
    Essence.reindex

    Searchkick.disable_callbacks
  end

  config.around(:each, :search) do |example|
    # Docs don't have the next two but without the old db entries remain in the index
    Collection.reindex
    Item.reindex
    Essence.reindex
    Searchkick.callbacks(:inline) do
      example.run
    end
  end
end
