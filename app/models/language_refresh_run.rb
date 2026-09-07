class LanguageRefreshRun < ApplicationRecord
  STATUSES = { running: 'running', completed: 'completed', failed: 'failed' }.freeze

  enum :status, STATUSES, validate: true

  validates :status, presence: true

  scope :latest_first, -> { order(started_at: :desc) }
end
