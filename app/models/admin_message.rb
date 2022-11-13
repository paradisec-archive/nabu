# ## Schema Information
#
# Table name: `admin_messages`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`id`**          | `integer`          | `not null, primary key`
# **`finish_at`**   | `datetime`         | `not null`
# **`message`**     | `text(65535)`      | `not null`
# **`start_at`**    | `datetime`         | `not null`
# **`created_at`**  | `datetime`         |
# **`updated_at`**  | `datetime`         |
#

class AdminMessage < ApplicationRecord
  has_paper_trail

  validates :message, presence: true
  validates :start_at, presence: true
  validates :finish_at, presence: true
end
