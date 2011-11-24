class CollectionLanguage < ActiveRecord::Base
  belongs_to :language
  belongs_to :collection
end
