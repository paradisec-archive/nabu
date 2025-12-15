# ## Schema Information
#
# Table name: `countries_languages`
# Database name: `primary`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`id`**           | `integer`          | `not null, primary key`
# **`country_id`**   | `integer`          | `not null`
# **`language_id`**  | `integer`          | `not null`
#
# ### Indexes
#
# * `index_countries_languages_on_country_id_and_language_id` (_unique_):
#     * **`country_id`**
#     * **`language_id`**
#

class CountriesLanguage < ApplicationRecord
  has_paper_trail

  belongs_to :country
  belongs_to :language

  validates :country_id, presence: true
  # validates :language_id, presence: true

  def self.ransackable_attributes(_ = nil)
    %w[country_id id language_id]
  end
end
