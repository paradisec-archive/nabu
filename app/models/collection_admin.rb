class CollectionAdmin < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection

  validates :collection_id, :presence => true
  validates :user_id, :presence => true
end
