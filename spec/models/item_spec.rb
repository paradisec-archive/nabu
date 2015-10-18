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

require 'spec_helper'

describe Item do
  let(:item) { build(:item) }

  describe '#citation' do
    it 'uses DOI, not URI' do
      item.should_receive(:doi) { '' }
      item.citation
    end
  end
end
