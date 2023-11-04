# ## Schema Information
#
# Table name: `essences`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`id`**                       | `integer`          | `not null, primary key`
# **`bitrate`**                  | `integer`          |
# **`channels`**                 | `integer`          |
# **`derived_files_generated`**  | `boolean`          | `default(FALSE)`
# **`doi`**                      | `string(255)`      |
# **`duration`**                 | `float(24)`        |
# **`filename`**                 | `string(255)`      |
# **`fps`**                      | `integer`          |
# **`mimetype`**                 | `string(255)`      |
# **`samplerate`**               | `integer`          |
# **`size`**                     | `bigint`           |
# **`created_at`**               | `datetime`         |
# **`updated_at`**               | `datetime`         |
# **`item_id`**                  | `integer`          |
#
# ### Indexes
#
# * `index_essences_on_item_id`:
#     * **`item_id`**
#

require 'rails_helper'

describe Essence do
  let(:item) { create(:item) }

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

  describe '#citation' do
    let(:essence) { create(:sound_essence, doi: doi) }

    context 'DOI exists' do
      let(:doi) { 'something' }

      it 'uses DOI, not URI' do
        expect(essence).to receive(:doi) { doi }.twice
        essence.citation
      end

      it 'does not blow up' do
        essence.citation
      end
    end

    context 'DOI nil' do
      let(:doi) { nil }

      it 'uses URI' do
        expect(essence).to receive(:doi) { doi }.once
        expect(essence).to receive(:full_path) { '' }
        essence.citation
      end

      it 'does not blow up' do
        essence.citation
      end
    end
  end
end
