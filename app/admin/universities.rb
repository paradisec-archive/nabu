# ## Schema Information
#
# Table name: `universities`
#
# ### Columns
#
# Name                    | Type               | Attributes
# ----------------------- | ------------------ | ---------------------------
# **`id`**                | `integer`          | `not null, primary key`
# **`name`**              | `string(255)`      |
# **`party_identifier`**  | `string(255)`      |
# **`created_at`**        | `datetime`         | `not null`
# **`updated_at`**        | `datetime`         | `not null`
#
ActiveAdmin.register University do
  menu :parent => "Other Entities"
  config.sort_order = "name_asc"

  permit_params :name, :party_identifier

  before_destroy :check_dependent

  # Don't filter by collections of items
  filter :name
  filter :created_at
  filter :updated_at
  filter :party_identifier

  controller do
    def check_dependent(object)
      if object.items.count > 0 || object.collections.count > 0
        flash[:error] = "ERROR: University used in items or collections - cannot be removed."
        return false
      end
    end
  end
end
