class Essence < ActiveRecord::Base
  belongs_to :item

  validates :filename, :presence => true
  validates :mimetype, :presence => true
  validates :bitrate, :numericality => {:only_integer => true, :greater_than => 0}
  validates :samplerate, :numericality => {:only_integer => true, :greater_than => 0}
  validates :size, :presence => true, :numericality => {:only_integer => true, :greater_than => 0}
  validates :duration, :numericality => {:greater_than => 0}
  validates :channels, :numericality => true
  validates :fps, :numericality => {:only_integer => true, :greater_than => 0}
end
