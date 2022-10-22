# == Schema Information
#
# Table name: grants
#
#  id               :integer          not null, primary key
#  collection_id    :integer
#  grant_identifier :string(255)
#  funding_body_id  :integer
#

class Grant < ActiveRecord::Base
  has_paper_trail

  belongs_to :collection
  belongs_to :funding_body

  validates_uniqueness_of :grant_identifier, scope: [:collection_id, :funding_body_id], allow_blank: true, allow_nil: true

  scope :alpha, -> { order('funding_body.name') }
end
