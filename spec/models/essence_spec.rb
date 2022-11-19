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
  let(:essence) { create(:sound_essence, doi: doi) }

  describe '#citation' do
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
