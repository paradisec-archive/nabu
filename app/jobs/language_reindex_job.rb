class LanguageReindexJob < ApplicationJob
  queue_as :default

  def perform(language)
    content_item_ids = language.item_content_languages.pluck(:item_id)
    item_ids = content_item_ids | language.item_subject_languages.pluck(:item_id)
    # A collection indexes its items' content languages as well as its own.
    collection_ids = language.collection_languages.pluck(:collection_id) | Item.where(id: content_item_ids).distinct.pluck(:collection_id)

    Item.where(id: item_ids).reindex(mode: :async)
    Essence.where(item_id: content_item_ids).reindex(mode: :async)
    Collection.where(id: collection_ids).reindex(mode: :async)
  end
end
