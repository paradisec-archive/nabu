# ## Schema Information
#
# Table name: `item_data_types`
#
# ### Columns
#
# Name                | Type               | Attributes
# ------------------- | ------------------ | ---------------------------
# **`id`**            | `integer`          | `not null, primary key`
# **`data_type_id`**  | `integer`          | `not null`
# **`item_id`**       | `integer`          | `not null`
#
# ### Indexes
#
# * `index_item_data_types_on_data_type_id`:
#     * **`data_type_id`**
# * `index_item_data_types_on_item_id`:
#     * **`item_id`**
#

class ItemDataType < ApplicationRecord
  has_paper_trail

  belongs_to :data_type
  belongs_to :item

  validates :data_type_id, presence: true
  # validates :item_id, :presence => true
end
