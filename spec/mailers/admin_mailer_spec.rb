require 'rails_helper'

describe AdminMailer, type: :mailer do
  describe '#unconfirmed_users_deleted_report' do
    let(:report_data) do
      {
        total_deleted: 2,
        total_failed: 1,
        deleted_users: [
          { id: 1, name: 'Deleted User One', email: 'one@example.org', created_at: 30.days.ago, created_days_ago: 30 },
          { id: 2, name: 'Deleted User Two', email: nil, created_at: 20.days.ago, created_days_ago: 20 }
        ],
        failed_deletions: [
          { id: 3, name: 'Kept User', email: 'three@example.org', errors: ['has dependent records'] }
        ]
      }
    end

    let(:mail) { described_class.with(report_data:).unconfirmed_users_deleted_report }

    # Regression for NABU-Q5: `mail(subject:)` referenced a non-existent `subject` method
    # (the local was `subject_line`), so the weekly cron always raised NoMethodError before
    # the body even rendered.
    it 'sets a subject that includes the deleted and failed counts' do
      expect(mail.subject).to eq('[NABU Admin] Unconfirmed Users Deleted: 2 accounts removed (1 failed)')
    end

    it 'omits the failed suffix when nothing failed' do
      report_data[:total_failed] = 0
      report_data[:failed_deletions] = []

      expect(mail.subject).to eq('[NABU Admin] Unconfirmed Users Deleted: 2 accounts removed')
    end

    it 'renders the body listing deleted and failed users without raising' do
      body = mail.body.to_s

      expect(body).to include('2 unconfirmed user accounts have been deleted')
      expect(body).to include('Deleted User One')
      expect(body).to include('Failed Deletions')
      expect(body).to include('Kept User')
      expect(body).to include('has dependent records')
    end
  end
end
