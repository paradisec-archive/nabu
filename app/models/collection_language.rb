# == Schema Information
#
# Table name: collection_languages
#
#  id            :integer          not null, primary key
#  collection_id :integer
#  language_id   :integer
#

class CollectionLanguage < ApplicationRecord
  has_paper_trail

  belongs_to :language
  belongs_to :collection

  validates :language_id, :presence => true
  #validates :collection_id, :presence => true
end
