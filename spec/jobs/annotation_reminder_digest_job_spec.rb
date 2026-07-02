require 'rails_helper'

describe AnnotationReminderDigestJob, type: :job do
  around do |example|
    original = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original
  end

  let(:uploader) { create(:user) }
  let(:other_uploader) { create(:user) }
  let(:item) { create(:item) }

  def make_essence(filename:, mimetype:, created_at: Time.current, created_by: uploader)
    create(:essence, item: item, filename: filename, mimetype: mimetype, size: 100,
                     created_at: created_at, created_by: created_by)
  end

  it 'emails the uploader for an unmapped recent transcript' do
    make_essence(filename: 'a.eaf', mimetype: 'text/xml')
    expect { described_class.new.perform }
      .to have_enqueued_mail(AnnotationReminderMailer, :daily_digest)
      .once
  end

  it 'does not email when the transcript already has a mapping' do
    # Non-matching basenames so the mapping comes solely from the explicit link below,
    # not the auto-linking callback (EssenceAnnotationMatcher).
    eaf = make_essence(filename: 'a.eaf', mimetype: 'text/xml')
    mp3 = make_essence(filename: 'b.mp3', mimetype: 'audio/mp3')
    EssenceAnnotation.create!(annotation_essence: eaf, target_essence: mp3)
    expect { described_class.new.perform }.not_to have_enqueued_mail(AnnotationReminderMailer)
  end

  it 'does not email for essences older than the window' do
    make_essence(filename: 'old.eaf', mimetype: 'text/xml', created_at: 30.days.ago)
    expect { described_class.new.perform }.not_to have_enqueued_mail(AnnotationReminderMailer)
  end

  it 'does not email for media essences (only transcripts)' do
    make_essence(filename: 'a.mp3', mimetype: 'audio/mp3')
    expect { described_class.new.perform }.not_to have_enqueued_mail(AnnotationReminderMailer)
  end

  it 'does not email when there is no uploader on record' do
    make_essence(filename: 'a.eaf', mimetype: 'text/xml', created_by: nil)
    expect { described_class.new.perform }.not_to have_enqueued_mail(AnnotationReminderMailer)
  end

  it 'sends one email per uploader, grouping their unmapped transcripts' do
    make_essence(filename: 'a.eaf', mimetype: 'text/xml', created_by: uploader)
    make_essence(filename: 'b.eaf', mimetype: 'text/xml', created_by: uploader)
    make_essence(filename: 'c.eaf', mimetype: 'text/xml', created_by: other_uploader)
    expect { described_class.new.perform }
      .to have_enqueued_mail(AnnotationReminderMailer, :daily_digest)
      .twice
  end
end
