ActiveAdmin.register AgentRole do
  menu :parent => "Other Entities"
  config.sort_order = "name_asc"

  before_destroy :check_dependent

  # Don't filter by item_agents
  filter :name

  controller do
    def check_dependent(object)
      if object.item_agents.count > 0
        flash[:error] = "ERROR: Role used in items - cannot be removed."
        return false
      end
    end
  end
end
