class LanguageRefreshRun < ApplicationRecord
  STATUSES = { running: 'running', completed: 'completed', failed: 'failed' }.freeze

  enum :status, STATUSES, validate: true

  validates :status, presence: true
end
