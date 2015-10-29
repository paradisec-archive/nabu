# == Schema Information
#
# Table name: essences
#
#  id         :integer          not null, primary key
#  item_id    :integer
#  filename   :string(255)
#  mimetype   :string(255)
#  bitrate    :integer
#  samplerate :integer
#  size       :integer
#  duration   :float
#  channels   :integer
#  fps        :integer
#  created_at :datetime
#  updated_at :datetime
#  doi        :string(255)
#

require 'spec_helper'

describe Essence do
  let(:essence) { create(:sound_essence) }

  describe '#citation' do
    it 'uses DOI' do
      pending 'pending spec'
      essence.should_receive(:doi) { '' }
      essence.citation
    end
  end
end
