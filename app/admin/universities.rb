ActiveAdmin.register University do
  menu :parent => "Other Entities"
  config.sort_order = "name"

  before_destroy :check_dependent

  controller do
    def check_dependent(object)
      if object.items.count > 0 || object.collections.count > 0
        flash[:error] = "ERROR: University used in items or collections - cannot be removed."
        return false
      end
    end
  end
end
