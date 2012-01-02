class Essence < ActiveRecord::Base
  belongs_to :item

  validates :item, :associated => true
  validates :filename, :presence => true
  validates :mimetype, :presence => true
  validates :bitrate, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}
  validates :samplerate, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}
  validates :size, :presence => true, :numericality => {:only_integer => true, :greater_than => 0}
  validates :duration, :numericality => {:greater_than => 0, :allow_nil => true}
  validates :channels, :numericality => {:greater_than => 0, :allow_nil => true}
  validates :fps, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}

  attr_accessible :item, :item_id, :filename, :mimetype, :bitrate, :samplerate, :size, :duration, :channels, :fps
end
