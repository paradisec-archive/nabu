# ## Schema Information
#
# Table name: `essences`
# Database name: `primary`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`id`**                       | `integer`          | `not null, primary key`
# **`bitrate`**                  | `bigint`           |
# **`channels`**                 | `integer`          |
# **`derived_files_generated`**  | `boolean`          | `default(FALSE)`
# **`doi`**                      | `string(255)`      |
# **`duration`**                 | `float(24)`        |
# **`extracted_content`**        | `text(4294967295)`  |
# **`extracted_content_type`**   | `string(255)`      |
# **`filename`**                 | `string(255)`      |
# **`fps`**                      | `integer`          |
# **`mimetype`**                 | `string(255)`      |
# **`samplerate`**               | `integer`          |
# **`size`**                     | `bigint`           |
# **`created_at`**               | `datetime`         |
# **`updated_at`**               | `datetime`         |
# **`created_by_id`**            | `bigint`           |
# **`item_id`**                  | `integer`          |
#
# ### Indexes
#
# * `index_essences_on_created_by_id`:
#     * **`created_by_id`**
# * `index_essences_on_item_id`:
#     * **`item_id`**
# * `index_essences_on_item_id_and_filename` (_unique_):
#     * **`item_id`**
#     * **`filename`**
#
# ### Foreign Keys
#
# * `fk_rails_...`:
#     * **`created_by_id => users.id`**
#

require 'rails_helper'
require Rails.root.join "spec/concerns/identifiable_by_doi_spec.rb"

describe Essence, type: :model do
  let(:item) { create(:item) }

  it_behaves_like 'identifiable by doi', 'item'


  describe 'no zero size files' do
    it 'does allow non-zero size files' do
      essence = described_class.new(filename: 'item.jpg', size: 100, mimetype: 'image/jpg', item: item)
      expect(essence).to be_valid
    end

    it 'does not allow zero size files' do
      essence = described_class.new(filename: 'item.jpg', size: 0, mimetype: 'image/jpg', item: item)
      expect(essence).not_to be_valid
      expect(essence.errors.messages).to include(size: include("must be greater than 0"))
    end

    it 'does allow zero size files for annis' do
      essence = described_class.new(filename: 'item.annis', size: 0, mimetype: 'image/jpg', item: item)
      expect(essence).to be_valid
    end
  end

  describe 'auto-linking annotations on create' do
    it 'links a new transcript to existing media sharing its basename' do
      media = create(:essence, item: item, filename: 'interview.mp3', mimetype: 'audio/mp3', size: 100)
      transcript = create(:essence, item: item, filename: 'interview.eaf', mimetype: 'text/xml', size: 100)

      expect(transcript.reload.annotates).to contain_exactly(media)
    end
  end

  describe 'archive statistics', :no_catalog_upload do
    let(:as_of) { Date.parse('2020-06-30') }

    before do
      create(:essence, item: item, filename: 'a.wav', mimetype: 'audio/wav', size: 100, duration: 10, created_at: '2020-01-01')
      create(:essence, item: item, filename: 'b.wav', mimetype: 'audio/wav', size: 200, duration: 20, created_at: '2020-02-01')
      create(:essence, item: item, filename: 'c.jpg', mimetype: 'image/jpeg', size: 50, duration: nil, created_at: '2020-03-01')
      create(:essence, item: item, filename: 'd.mp4', mimetype: 'video/mp4', size: 400, duration: 40, created_at: '2020-12-01')
    end

    describe '.mimetype_stats' do
      it 'totals each mimetype present as at the given date, most files first' do
        expect(described_class.mimetype_stats(as_of)).to eq([
                                                             { mimetype: 'audio/wav', files: 2, bytes: 300, duration: 30 },
                                                             { mimetype: 'image/jpeg', files: 1, bytes: 50, duration: nil }
                                                           ])
      end
    end

    describe '.archive_stats' do
      it 'folds the mimetype totals into whole-of-archive figures' do
        expect(described_class.archive_stats(as_of)).to eq(
          count: 3, duration: 30, size: 350,
          video_size: 0, audio_size: 300, image_size: 50, application_size: 0, text_size: 0
        )
      end

      it 'derives the figures from pre-computed totals when given them, so callers can share a single scan' do
        stats = [{ mimetype: 'text/plain', files: 7, bytes: 70, duration: nil }]

        expect(described_class.archive_stats(as_of, stats)).to include(count: 7, size: 70, duration: 0, text_size: 70)
      end
    end
  end
end
