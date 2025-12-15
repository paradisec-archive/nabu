# ## Schema Information
#
# Table name: `latlon_boundaries`
# Database name: `primary`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`id`**           | `integer`          | `not null, primary key`
# **`east_limit`**   | `decimal(6, 3)`    | `not null`
# **`north_limit`**  | `decimal(6, 3)`    | `not null`
# **`south_limit`**  | `decimal(6, 3)`    | `not null`
# **`west_limit`**   | `decimal(6, 3)`    | `not null`
# **`wrapped`**      | `boolean`          | `default(FALSE)`
# **`country_id`**   | `integer`          | `not null`
#
# ### Indexes
#
# * `index_latlon_boundaries_on_country_id`:
#     * **`country_id`**
#

class LatlonBoundary < ApplicationRecord
  has_paper_trail

  belongs_to :country

  validates :north_limit, :south_limit, :west_limit, :east_limit, :country, presence: true

  def self.ransackable_attributes(_ = nil)
    %w[country_id east_limit id north_limit south_limit west_limit wrapped]
  end

  def self.ransackable_associations(_ = nil)
    %w[country versions]
  end
end
