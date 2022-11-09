# ## Schema Information
#
# Table name: `item_agents`
#
# ### Columns
#
# Name                 | Type               | Attributes
# -------------------- | ------------------ | ---------------------------
# **`id`**             | `integer`          | `not null, primary key`
# **`agent_role_id`**  | `integer`          | `not null`
# **`item_id`**        | `integer`          | `not null`
# **`user_id`**        | `integer`          | `not null`
#
# ### Indexes
#
# * `index_item_agents_on_item_id_and_user_id_and_agent_role_id` (_unique_):
#     * **`item_id`**
#     * **`user_id`**
#     * **`agent_role_id`**
#

class ItemAgent < ApplicationRecord
  has_paper_trail

  belongs_to :user
  belongs_to :agent_role
  belongs_to :item

  validates :user, :presence => true
  validates :agent_role_id, :presence => true
  validates_uniqueness_of :item_id, :scope => [:agent_role_id, :user_id]

  delegate :name, :to => :user, :prefix => true, :allow_nil => true
  delegate :name, :to => :agent_role, :prefix => :role, :allow_nil => true
end
