class ItemSubjectLanguage < ActiveRecord::Base
  belongs_to :language
  belongs_to :item

  attr_accessible :language_id, :item_id

  validates :language_id, :presence => true
  validates :item_id, :presence => true
end
