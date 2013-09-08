class Download < ActiveRecord::Base
  belongs_to :user
  belongs_to :essence

  has_one :item, :through => :essence

  delegate :collection, :to => :item

  attr_accessible :user, :essence

  validates :user, :associated => true
  validates :essence, :associated => true
end
