class Comment < ActiveRecord::Base
  opinio
  has_paper_trail

  paginates_per 5
end
