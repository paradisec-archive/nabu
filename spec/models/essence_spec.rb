# == Schema Information
#
# Table name: essences
#
#  id                      :integer          not null, primary key
#  item_id                 :integer
#  filename                :string(255)
#  mimetype                :string(255)
#  bitrate                 :integer
#  samplerate              :integer
#  size                    :integer
#  duration                :float
#  channels                :integer
#  fps                     :integer
#  created_at              :datetime
#  updated_at              :datetime
#  doi                     :string(255)
#  derived_files_generated :boolean
#

require 'rails_helper'

describe Essence do
  let(:essence) { create(:sound_essence, doi: doi) }

  describe '#citation' do
    context 'DOI exists' do
      let(:doi) { 'something' }

      it 'uses DOI, not URI' do
        essence.should_receive(:doi) { doi }.twice
        essence.citation
      end

      it 'does not blow up' do
        essence.citation
      end
    end

    context 'DOI nil' do
      let(:doi) { nil }

      it 'uses URI' do
        essence.should_receive(:doi) { doi }.once
        essence.should_receive(:full_path) { '' }
        essence.citation
      end

      it 'does not blow up' do
        essence.citation
      end
    end
  end
end
