class PaperTrail::Version < ActiveRecord::Base
  def self.ransackable_attributes(_ = nil)
    %w[created_at event id item_id item_type object object_changes whodunnit]
  end
end
