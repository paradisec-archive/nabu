# ## Schema Information
#
# Table name: `language_refresh_runs`
# Database name: `primary`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`id`**           | `bigint`           | `not null, primary key`
# **`finished_at`**  | `datetime`         |
# **`report`**       | `text(16777215)`   |
# **`sources`**      | `json`             |
# **`started_at`**   | `datetime`         |
# **`status`**       | `string(255)`      | `default("running"), not null`
# **`created_at`**   | `datetime`         | `not null`
# **`updated_at`**   | `datetime`         | `not null`
#
class LanguageRefreshRun < ApplicationRecord
  STATUSES = { running: 'running', completed: 'completed', failed: 'failed' }.freeze

  enum :status, STATUSES, validate: true

  validates :status, presence: true
end
