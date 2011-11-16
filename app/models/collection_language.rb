class CollectionLanguage < ActiveRecord::Base
  belongs_to :language
  belongs_to :collection

  validates :language_id, :presence => true
end
