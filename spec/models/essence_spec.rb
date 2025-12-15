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
# * `index_essences_on_item_id_and_filename` (_unique_):
#     * **`item_id`**
#     * **`filename`**
#

require 'rails_helper'
require Rails.root.join "spec/concerns/identifiable_by_doi_spec.rb"

describe Essence, type: :model do
  include_examples 'identifiable by doi', 'item'

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
end
