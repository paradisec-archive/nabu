# ## Schema Information
#
# Table name: `item_data_categories`
#
# ### Columns
#
# Name                    | Type               | Attributes
# ----------------------- | ------------------ | ---------------------------
# **`id`**                | `integer`          | `not null, primary key`
# **`data_category_id`**  | `integer`          | `not null`
# **`item_id`**           | `integer`          | `not null`
#
# ### Indexes
#
# * `index_item_data_categories_on_item_id_and_data_category_id` (_unique_):
#     * **`item_id`**
#     * **`data_category_id`**
#

class ItemDataCategory < ApplicationRecord
  has_paper_trail

  belongs_to :data_category
  belongs_to :item

  validates :data_category_id, presence: true
  # validates :item_id, :presence => true
end
