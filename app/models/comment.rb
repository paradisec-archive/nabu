class Comment < ActiveRecord::Base
  opinio

  paginates_per 5
end
