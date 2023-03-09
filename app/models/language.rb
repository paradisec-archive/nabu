# ## Schema Information
#
# Table name: `languages`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`id`**           | `integer`          | `not null, primary key`
# **`code`**         | `string(255)`      |
# **`east_limit`**   | `float(24)`        |
# **`name`**         | `string(255)`      |
# **`north_limit`**  | `float(24)`        |
# **`retired`**      | `boolean`          |
# **`south_limit`**  | `float(24)`        |
# **`west_limit`**   | `float(24)`        |
#
# ### Indexes
#
# * `index_languages_on_code` (_unique_):
#     * **`code`**
#

class Language < ApplicationRecord
  has_paper_trail

  validates :name, :presence => true
  validates :code, :presence => true, :uniqueness => { case_sensitive: false }

  scope :alpha, -> { order(:name) }

  def name_with_code
    "#{name} - #{code}"
  end

  def language_archive_link
    "http://www.language-archives.org/language/#{code}"
  end

  has_many :countries_languages
  has_many :countries, :through => :countries_languages, :dependent => :destroy
  accepts_nested_attributes_for :countries_languages, :allow_destroy => true
  #validates :countries, :length => { :minimum => 1 }

  has_many :item_content_languages
  has_many :items_for_content, :through => :item_content_languages, :source => :item, :dependent => :restrict_with_exception

  has_many :item_subject_languages
  has_many :items_for_subject, :through => :item_subject_languages, :source => :item, :dependent => :restrict_with_exception

  has_many :collection_languages
  has_many :collections, :through => :collection_languages, :dependent => :restrict_with_exception
end
