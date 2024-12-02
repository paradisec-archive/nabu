# ## Schema Information
#
# Table name: `collection_languages`
#
# ### Columns
#
# Name                 | Type               | Attributes
# -------------------- | ------------------ | ---------------------------
# **`id`**             | `integer`          | `not null, primary key`
# **`collection_id`**  | `integer`          |
# **`language_id`**    | `integer`          |
#
# ### Indexes
#
# * `index_collection_languages_on_collection_id_and_language_id` (_unique_):
#     * **`collection_id`**
#     * **`language_id`**
#

class CollectionLanguage < ApplicationRecord
  has_paper_trail

  belongs_to :language
  belongs_to :collection

  validates :language_id, presence: true
  # validates :collection_id, presence: true

  def self.ransackable_attributes(_ = nil)
    %w[collection_id id language_id]
  end
end
