class ItemAgent < ActiveRecord::Base
  belongs_to :user
  belongs_to :agent_role
  belongs_to :item
end
