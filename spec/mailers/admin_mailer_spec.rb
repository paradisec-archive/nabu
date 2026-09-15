require 'rails_helper'

describe AdminMailer, type: :mailer do
  describe '#unconfirmed_users_deleted_report' do
    let(:deleted_users) do
      [
        { id: 1, name: 'Deleted User One', email: 'one@example.org', created_at: 30.days.ago },
        { id: 2, name: 'Deleted User Two', email: nil, created_at: 20.days.ago }
      ]
    end

    let(:mail) { described_class.with(deleted_users:).unconfirmed_users_deleted_report }

    # Regression for NABU-Q5: `mail(subject:)` referenced a non-existent `subject` method
    # (the local was `subject_line`), so the weekly report always raised NoMethodError before
    # the body even rendered.
    it 'sets a subject that includes the deleted count' do
      expect(mail.subject).to eq('[NABU Admin] Unconfirmed Users Deleted: 2 accounts removed')
    end

    it 'renders the body listing the deleted users without raising' do
      body = mail.body.to_s

      expect(body).to include('2 unconfirmed user accounts have been deleted')
      expect(body).to include('Deleted User One')
      expect(body).to include('No email')
      expect(body).to include('30 days ago')
    end
  end
end
