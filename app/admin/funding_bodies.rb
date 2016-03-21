ActiveAdmin.register FundingBody do
  menu :parent => "Other Entities"
  config.sort_order = "name_asc"

  before_destroy :check_dependent

  # Don't filter by grants or collections
  filter :name
  filter :key_prefix
  filter :created_at
  filter :updated_at

  controller do
    def check_dependent(object)
      if object.collections.count > 0
        flash[:error] = "ERROR: Funding body used in collections and cannot be removed."
        return false
      end
    end
  end
end
