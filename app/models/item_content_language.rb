# ## Schema Information
#
# Table name: `item_content_languages`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`id`**           | `integer`          | `not null, primary key`
# **`item_id`**      | `integer`          | `not null`
# **`language_id`**  | `integer`          | `not null`
#
# ### Indexes
#
# * `index_item_content_languages_on_item_id_and_language_id` (_unique_):
#     * **`item_id`**
#     * **`language_id`**
#

class ItemContentLanguage < ApplicationRecord
  has_paper_trail

  belongs_to :language
  belongs_to :item

  validates :language_id, presence: true
  # validates :item_id, presence: true

  def self.ransackable_attributes(_ = nil)
    %w[id item_id language_id]
  end
end
