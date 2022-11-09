# ## Schema Information
#
# Table name: `item_countries`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`id`**          | `integer`          | `not null, primary key`
# **`country_id`**  | `integer`          | `not null`
# **`item_id`**     | `integer`          | `not null`
#
# ### Indexes
#
# * `index_item_countries_on_item_id_and_country_id` (_unique_):
#     * **`item_id`**
#     * **`country_id`**
#

class ItemCountry < ApplicationRecord
  has_paper_trail

  belongs_to :country
  belongs_to :item

  validates :country_id, :presence => true
  #validates :item_id, :presence => true
end
