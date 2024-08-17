RSpec.configure do |config|
   config.before(:suite) do
    Collection.reindex
    Item.reindex

    Searchkick.disable_callbacks
  end

  config.around(:each, search: true) do |example|
    # Docs don't have the next two but without the old db entries remain in the index
    Collection.reindex
    Item.reindex
    Searchkick.callbacks(nil) do
      example.run
    end
  end
end
