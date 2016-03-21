class AdminMessage < ActiveRecord::Base
  attr_accessible :finish_at, :message, :start_at
end
