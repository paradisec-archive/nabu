# ## Schema Information
#
# Table name: `access_conditions`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`id`**          | `integer`          | `not null, primary key`
# **`name`**        | `string(255)`      |
# **`created_at`**  | `datetime`         | `not null`
# **`updated_at`**  | `datetime`         | `not null`
#

class AccessCondition < ApplicationRecord
  has_paper_trail

  scope :alpha, -> { order(:name) }

  validates :name, :presence => true

  has_many :items,       :dependent => :restrict_with_exception
  has_many :collections, :dependent => :restrict_with_exception

  # Class method so that it can handle the scenario of `access_condition` being nil.
  # Method not called access_class so that it isn't confused with the concept of a Ruby class.
  def self.access_classification(access_condition)
    access_condition_name = access_condition && access_condition.name
    case
    when access_condition_name && access_condition_name.start_with?('Open')
      'open'
    when access_condition_name && access_condition_name.start_with?('Closed')
      'closed'
    else
      'other'
    end
  end
end
