require 'rails_helper'

describe LanguageReindexJob, :no_catalog_upload, :search do
  include ActiveJob::TestHelper

  def indexed(record)
    record.class.search_index.retrieve(record)
  end

  it 'gives every search document holding the Language its new Label', :aggregate_failures do
    language = create(:language, name: 'Warlpiri', code: 'wbp')
    tagged_collection = create(:collection, :reindex, languages: [language])
    content_item = create(:item, :reindex, content_languages: [language])
    subject_item = create(:item, :reindex, subject_languages: [language])
    essence = create(:essence, :reindex, item: content_item, size: 16)
    # A collection can drop a Language its items still carry; it indexes their content languages all the same.
    CollectionLanguage.where(collection: content_item.collection, language:).delete_all

    perform_enqueued_jobs { language.update!(name: 'Walpiri') }
    [Collection, Item, Essence].each { |model| model.search_index.refresh }

    label = 'Walpiri (wbp) · ISO 639-3'
    expect(indexed(tagged_collection)['languages']).to eq([label])
    expect(indexed(content_item)['content_languages']).to eq([label])
    expect(indexed(content_item)['languages_with_code']).to eq([label])
    expect(indexed(content_item.collection)['languages_with_code']).to eq([label])
    expect(indexed(subject_item)['subject_languages']).to eq([label])
    expect(indexed(essence)['languages_with_code']).to eq([label])
  end
end
