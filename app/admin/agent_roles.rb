# ## Schema Information
#
# Table name: `agent_roles`
# Database name: `primary`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(255)`      | `not null`
#
ActiveAdmin.register AgentRole do
  menu parent: 'Other Entities'
  config.sort_order = 'name_asc'

  before_destroy :check_dependent

  permit_params :name

  # Don't filter by item_agents
  filter :name

  controller do
    def check_dependent(object)
      if object.item_agents.count > 0
        flash[:error] = 'ERROR: Role used in items - cannot be removed.'
        false
      end
    end
  end
end
