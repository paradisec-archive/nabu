require 'rails_helper'

describe EssenceAnnotationMatcher do
  let(:item) { create(:item) }

  def essence(filename, mimetype)
    create(:essence, item: item, filename: filename, mimetype: mimetype, size: 100)
  end

  describe '.link_for' do
    it 'links a new transcript to existing media with a matching basename' do
      media = essence('interview.mp3', 'audio/mp3')
      transcript = essence('interview.eaf', 'text/xml')

      expect(transcript.reload.annotates).to contain_exactly(media)
    end

    it 'links new media back to an existing transcript with a matching basename (bidirectional)' do
      transcript = essence('interview.eaf', 'text/xml')
      media = essence('interview.mp3', 'audio/mp3')

      expect(media.reload.annotated_by).to contain_exactly(transcript)
    end

    it 'matches basenames case-insensitively' do
      media = essence('Interview.MP3', 'audio/mp3')
      transcript = essence('interview.eaf', 'text/xml')

      expect(transcript.reload.annotates).to contain_exactly(media)
    end

    it 'links to every media format sharing the basename' do
      wav = essence('interview.wav', 'audio/wav')
      mp4 = essence('interview.mp4', 'video/mp4')
      transcript = essence('interview.eaf', 'text/xml')

      expect(transcript.reload.annotates).to contain_exactly(wav, mp4)
    end

    it 'does not link when no sibling basename matches' do
      essence('interview.mp3', 'audio/mp3')
      transcript = essence('other.eaf', 'text/xml')

      expect(transcript.reload.annotates).to be_empty
    end

    it 'does not link media to media or transcript to transcript' do
      essence('interview.eaf', 'text/xml')
      other_transcript = essence('interview.trs', 'text/xml')

      expect(other_transcript.reload.annotates).to be_empty
      expect(other_transcript.reload.annotated_by).to be_empty
    end

    it 'is a no-op for a non-annotatable, non-transcript file' do
      essence('interview.mp3', 'audio/mp3')

      expect { essence('interview.pdf', 'application/pdf') }.not_to change(EssenceAnnotation, :count)
    end

    it 'does not match siblings in a different item' do
      other_item = create(:item)
      create(:essence, item: other_item, filename: 'interview.mp3', mimetype: 'audio/mp3', size: 100)
      transcript = essence('interview.eaf', 'text/xml')

      expect(transcript.reload.annotates).to be_empty
    end

    it 'is idempotent when re-run for the same essence' do
      media = essence('interview.mp3', 'audio/mp3')
      transcript = essence('interview.eaf', 'text/xml')

      expect { described_class.link_for(transcript) }.not_to change(EssenceAnnotation, :count)
      expect(transcript.reload.annotates).to contain_exactly(media)
    end

    it 'never raises when linking fails, and reports to Sentry' do
      transcript = essence('interview.eaf', 'text/xml')
      essence('interview.mp3', 'audio/mp3')
      allow(EssenceAnnotation).to receive(:find_or_create_by!).and_raise(StandardError, 'boom')

      expect(Sentry).to receive(:capture_exception)
      expect { described_class.link_for(transcript) }.not_to raise_error
    end

    it 'still links the remaining media when one pair fails' do
      wav = essence('interview.wav', 'audio/wav')
      mp3 = essence('interview.mp3', 'audio/mp3')
      allow(Sentry).to receive(:capture_exception)
      # Fail only the wav pair; the mp3 pair must still be linked (per-pair rescue).
      allow(EssenceAnnotation).to receive(:find_or_create_by!).and_call_original
      allow(EssenceAnnotation).to receive(:find_or_create_by!)
        .with(hash_including(target_essence: wav)).and_raise(StandardError, 'boom')

      transcript = essence('interview.eaf', 'text/xml')

      expect(transcript.reload.annotates).to contain_exactly(mp3)
    end

    it 'treats a lost create race (RecordNotUnique) as success without reporting' do
      essence('interview.mp3', 'audio/mp3')
      transcript = essence('interview.eaf', 'text/xml')
      # The pair already exists from the create callback; a re-run racing another writer raises.
      allow(EssenceAnnotation).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordNotUnique, 'dup')

      expect(Sentry).not_to receive(:capture_exception)
      expect { described_class.link_for(transcript) }.not_to raise_error
    end
  end
end
