ActiveAdmin.register FundingBody do
  menu :parent => "Other Entities"
  config.sort_order = "name"

  before_destroy :check_dependent

  controller do
    def check_dependent(object)
      if object.collections.count > 0
        flash[:error] = "ERROR: Funding body used in collections and cannot be removed."
        return false
      end
    end
  end
end
