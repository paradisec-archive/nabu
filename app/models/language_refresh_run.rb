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
  enum :status, %w[running completed failed].index_by(&:to_sym), validate: true

  after_initialize { self.sources ||= {} }

  # Named on every join-table row the Run rewrites, so a re-tag points back at the Run that made it.
  def whodunnit
    "Language Refresh Run #{id}"
  end

  def record_source(source, entry)
    update!(sources: sources.merge(source => entry))
  end

  # The row count a Source had the last time a Run applied it, the baseline for the shrink guard.
  def previous_rows(source)
    self.class.where(id: ...id)
      .where('JSON_UNQUOTE(JSON_EXTRACT(sources, ?)) = ?', "$.#{source}.status", 'applied')
      .order(id: :desc)
      .pick(:sources)
      &.dig(source, 'rows')
  end
end
