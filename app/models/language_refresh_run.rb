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

  after_initialize { self.sources ||= {} }

  def record_source(source, entry)
    update!(sources: sources.merge(source => entry))
  end

  # The row count a Source had the last time a Run applied it, the baseline for the shrink guard.
  def previous_rows(source)
    path = ->(key) { self.class.connection.quote("$.#{source}.#{key}") }

    self.class.where(id: ...id)
      .where(Arel.sql("sources->>#{path.call('status')} = 'applied'"))
      .order(id: :desc)
      .pick(Arel.sql("CAST(sources->>#{path.call('rows')} AS UNSIGNED)"))
  end
end
