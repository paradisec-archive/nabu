class Collection < ActiveRecord::Base
  belongs_to :collector
  belongs_to :university
  belongs_to :field_of_research
  belongs_to :country
end
