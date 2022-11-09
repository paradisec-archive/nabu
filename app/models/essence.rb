# ## Schema Information
#
# Table name: `essences`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`id`**                       | `integer`          | `not null, primary key`
# **`bitrate`**                  | `integer`          |
# **`channels`**                 | `integer`          |
# **`derived_files_generated`**  | `boolean`          | `default(FALSE)`
# **`doi`**                      | `string(255)`      |
# **`duration`**                 | `float(24)`        |
# **`filename`**                 | `string(255)`      |
# **`fps`**                      | `integer`          |
# **`mimetype`**                 | `string(255)`      |
# **`samplerate`**               | `integer`          |
# **`size`**                     | `bigint`           |
# **`created_at`**               | `datetime`         |
# **`updated_at`**               | `datetime`         |
# **`item_id`**                  | `integer`          |
#
# ### Indexes
#
# * `index_essences_on_item_id`:
#     * **`item_id`**
#

class Essence < ApplicationRecord
  include IdentifiableByDoi

  has_paper_trail

  belongs_to :item, counter_cache: true
  delegate :collection, to: :item

  validates :item, :associated => true
  validates :filename, :presence => true
  validates :mimetype, :presence => true
  validates :bitrate, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}
  validates :samplerate, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}
  validates :size, :presence => true, :numericality => {:only_integer => true, :greater_than => 0}
  validates :duration, :numericality => {:greater_than => 0, :allow_nil => true}
  validates :channels, :numericality => {:greater_than => 0, :allow_nil => true}
  validates :fps, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}

  # ensure that the item catalog gets updated when essences are added/removed
  after_create :update_catalog_file
  before_destroy :update_catalog_file

  def type
    types = mimetype.split("/",2)
    if types[1].nil?
      "unknown"
    else
      types[1].upcase
    end
  end

  def path
    Nabu::Application.config.archive_directory + "#{full_identifier}"
  end

  def full_identifier
    item.collection.identifier + '/' + item.identifier + '/' + filename
  end

  def next_essence
    current_essences = Essence.where(item_id: item_id).order(:filename)
    current_essence_index = current_essences.index { |essence| essence.id == id }

    current_essences[current_essence_index + 1]
  end

  def prev_essence
    current_essences = Essence.where(item_id: item_id).order(:filename)
    current_essence_index = current_essences.index { |essence| essence.id == id }

    current_essence_index == 0 ? nil : current_essences[current_essence_index - 1]
  end

  def citation
    cite = ""
    if item.collector
      cite += "#{collector_name} (collector)"
    end
    item.item_agents.group_by(&:user).map do |user, ias|
      cite += ", " unless cite == ""
      cite += "#{user.name} (#{ias.map(&:agent_role).map(&:name).join(', ')})"
    end
    cite += ", #{item.originated_on.year}" if item.originated_on
    cite += '. ' unless cite == ""
    cite += type
    cite += ". "
    # cite += filename
    # cite += ", "
    cite += " #{filename} at catalog.paradisec.org.au."
    if doi
      cite += " https://dx.doi.org/#{doi}"
    else
      cite += " #{full_path}"
    end
    cite
  end

  def title
    filename
  end

  def full_path
    # TODO: probably want to change this to be filename at some point, non-urgent though
    "#{item.full_path}/essences/#{id}"
  end

  def collector_name
    item.collector_name
  end

  # for DOI relationship linking: nil <- Collection <- Item <- Essence
  def parent
    item
  end

  private

  def update_catalog_file
    ItemCatalogService.new(item).delay.save_file
  end
end
