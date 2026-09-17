class LanguageReindexJob < ApplicationJob
  queue_as :default

  def perform(language)
    content_items = ItemContentLanguage.where(language:).select(:item_id)
    tagged_items = Item.where(id: content_items).or(Item.where(id: ItemSubjectLanguage.where(language:).select(:item_id)))
    # A collection indexes its items' content languages as well as its own.
    tagged_collections = Collection.where(id: CollectionLanguage.where(language:).select(:collection_id))
                                   .or(Collection.where(id: Item.where(id: content_items).select(:collection_id)))

    tagged_items.reindex(mode: :async)
    Essence.where(item_id: content_items).reindex(mode: :async)
    tagged_collections.reindex(mode: :async)
  end
end
