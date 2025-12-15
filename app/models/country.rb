# ## Schema Information
#
# Table name: `countries`
# Database name: `primary`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`code`**  | `string(255)`      |
# **`name`**  | `string(255)`      |
#
# ### Indexes
#
# * `index_countries_on_code` (_unique_):
#     * **`code`**
# * `index_countries_on_name` (_unique_):
#     * **`name`**
#

class Country < ApplicationRecord
  has_paper_trail

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :code, presence: true, uniqueness: { case_sensitive: false }

  scope :alpha, -> { order(:name) }

  def name_with_code
    "#{name} - #{code}"
  end

  has_many :countries_languages
  has_many :languages, through: :countries_languages, dependent: :restrict_with_exception

  has_one :latlon_boundary

  def language_archive_link
    "http://www.language-archives.org/country/#{code.upcase}"
  end

  def self.ransackable_attributes(_ = nil)
    %w[code id name]
  end
end
