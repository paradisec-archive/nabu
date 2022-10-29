# == Schema Information
#
# Table name: items
#
#  id                      :integer          not null, primary key
#  collection_id           :integer          not null
#  identifier              :string(255)      not null
#  private                 :boolean
#  title                   :string(255)      not null
#  url                     :string(255)
#  collector_id            :integer          not null
#  university_id           :integer
#  operator_id             :integer
#  description             :text             default(""), not null
#  originated_on           :date
#  language                :string(255)
#  dialect                 :string(255)
#  region                  :string(255)
#  discourse_type_id       :integer
#  access_condition_id     :integer
#  access_narrative        :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  metadata_exportable     :boolean
#  born_digital            :boolean
#  tapes_returned          :boolean
#  original_media          :text
#  received_on             :datetime
#  digitised_on            :datetime
#  ingest_notes            :text
#  metadata_imported_on    :datetime
#  metadata_exported_on    :datetime
#  tracking                :text
#  admin_comment           :text
#  external                :boolean          default(FALSE)
#  originated_on_narrative :text
#  north_limit             :float
#  south_limit             :float
#  west_limit              :float
#  east_limit              :float
#  doi                     :string(255)
#

require 'rails_helper'

describe Item do
  let(:item) { build(:item, doi: doi) }

  # FIXME: JF bring this back later - issue with stubbing
  # describe '#citation' do
  #   context 'DOI exists' do
  #     let(:doi) { 'something' }
  #
  #     it 'uses DOI, not URI' do
  #       item.should_receive(:doi) { doi }.twice
  #       item.citation
  #     end
  #   end
  #
  #   context 'DOI nil' do
  #     let(:doi) { nil }
  #
  #     it 'uses URI' do
  #       item.should_receive(:doi) { doi }.once
  #       item.should_receive(:full_path) { '' }
  #       item.citation
  #     end
  #   end
  # end
end
