# ## Schema Information
#
# Table name: `essence_annotations`
# Database name: `primary`
#
# ### Columns
#
# Name                         | Type               | Attributes
# ---------------------------- | ------------------ | ---------------------------
# **`id`**                     | `bigint`           | `not null, primary key`
# **`created_at`**             | `datetime`         | `not null`
# **`updated_at`**             | `datetime`         | `not null`
# **`annotation_essence_id`**  | `integer`          | `not null`
# **`target_essence_id`**      | `integer`          | `not null`
#
# ### Indexes
#
# * `index_essence_annotations_on_annotation_essence_id`:
#     * **`annotation_essence_id`**
# * `index_essence_annotations_on_target_essence_id`:
#     * **`target_essence_id`**
# * `index_essence_annotations_unique_pair` (_unique_):
#     * **`annotation_essence_id`**
#     * **`target_essence_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`annotation_essence_id => essences.id`**
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`target_essence_id => essences.id`**
#
require 'rails_helper'

describe EssenceAnnotation, type: :model do
  let(:item) { create(:item) }
  let(:other_item) { create(:item) }
  # Deliberately non-matching basenames so the auto-linking callback (EssenceAnnotationMatcher)
  # does not pre-create mappings; these tests exercise the association machinery directly.
  let(:mp3) { create(:essence, item: item, filename: 'recording.mp3', mimetype: 'audio/mp3', size: 100) }
  let(:eaf) { create(:essence, item: item, filename: 'transcript.eaf', mimetype: 'text/xml', size: 100) }
  let(:foreign_eaf) { create(:essence, item: other_item, filename: 'foreign.eaf', mimetype: 'text/xml', size: 100) }
  let(:pdf) { create(:essence, item: item, filename: 'notes.pdf', mimetype: 'application/pdf', size: 100) }

  describe 'validations' do
    it 'is valid for a transcript annotating media in the same item' do
      record = described_class.new(annotation_essence: eaf, target_essence: mp3)
      expect(record).to be_valid
    end

    it 'rejects mappings across items' do
      record = described_class.new(annotation_essence: foreign_eaf, target_essence: mp3)
      expect(record).not_to be_valid
      expect(record.errors[:base]).to include(a_string_matching(/same item/))
    end

    it 'rejects a non-transcript annotation essence' do
      record = described_class.new(annotation_essence: pdf, target_essence: mp3)
      expect(record).not_to be_valid
      expect(record.errors[:annotation_essence]).to be_present
    end

    it 'rejects a non-media target essence' do
      record = described_class.new(annotation_essence: eaf, target_essence: pdf)
      expect(record).not_to be_valid
      expect(record.errors[:target_essence]).to be_present
    end

    it 'prevents duplicate mappings' do
      described_class.create!(annotation_essence: eaf, target_essence: mp3)
      dup = described_class.new(annotation_essence: eaf, target_essence: mp3)
      expect(dup).not_to be_valid
    end
  end

  describe 'associations' do
    it 'is reachable from the transcript via .annotates' do
      described_class.create!(annotation_essence: eaf, target_essence: mp3)
      expect(eaf.reload.annotates).to include(mp3)
    end

    it 'is reachable from the media via .annotated_by' do
      described_class.create!(annotation_essence: eaf, target_essence: mp3)
      expect(mp3.reload.annotated_by).to include(eaf)
    end
  end

  describe 'cascade on essence destroy' do
    it 'removes mappings when the transcript is destroyed' do
      described_class.create!(annotation_essence: eaf, target_essence: mp3)
      expect { eaf.destroy }.to change(described_class, :count).by(-1)
    end

    it 'removes mappings when the media is destroyed' do
      described_class.create!(annotation_essence: eaf, target_essence: mp3)
      expect { mp3.destroy }.to change(described_class, :count).by(-1)
    end
  end

  describe Essence, type: :model do
    describe '#unmapped_transcript?' do
      let(:item) { create(:item) }
      let(:eaf) { create(:essence, item: item, filename: 'notes.eaf', mimetype: 'text/xml', size: 100) }
      let(:mp3) { create(:essence, item: item, filename: 'audio.mp3', mimetype: 'audio/mp3', size: 100) }

      it 'is true for a transcript with no outgoing mappings' do
        expect(eaf.unmapped_transcript?).to be true
      end

      it 'is false for a transcript with an outgoing mapping' do
        EssenceAnnotation.create!(annotation_essence: eaf, target_essence: mp3)
        expect(eaf.reload.unmapped_transcript?).to be false
      end

      it 'is false for a media file (regardless of mappings)' do
        expect(mp3.unmapped_transcript?).to be false
      end
    end
  end
end
