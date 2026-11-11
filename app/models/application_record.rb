class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Ransack 6 asks each model an association filter passes through, and raises if the model hasn't declared any
  def self.ransackable_associations(_ = nil)
    []
  end
end
