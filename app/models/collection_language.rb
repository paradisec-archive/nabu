class CollectionLanguage < ActiveRecord::Base
  belongs_to :language
  belongs_to :collection

  attr_accessible :language_id, :collection_id

  validates :language_id, :presence => true
  validates :collection_id, :presence => true
end
