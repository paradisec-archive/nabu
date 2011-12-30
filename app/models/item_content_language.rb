class ItemContentLanguage < ActiveRecord::Base
  belongs_to :language
  belongs_to :item
end
