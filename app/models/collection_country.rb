# ## Schema Information
#
# Table name: `collection_countries`
# Database name: `primary`
#
# ### Columns
#
# Name                 | Type               | Attributes
# -------------------- | ------------------ | ---------------------------
# **`id`**             | `integer`          | `not null, primary key`
# **`collection_id`**  | `integer`          |
# **`country_id`**     | `integer`          |
#
# ### Indexes
#
# * `index_collection_countries_on_collection_id_and_country_id` (_unique_):
#     * **`collection_id`**
#     * **`country_id`**
#

class CollectionCountry < ApplicationRecord
  has_paper_trail

  belongs_to :country
  belongs_to :collection

  validates :country_id, presence: true
  # validates :collection_id, :presence => true
end
