# ## Schema Information
#
# Table name: `funding_bodies`
#
# ### Columns
#
# Name              | Type               | Attributes
# ----------------- | ------------------ | ---------------------------
# **`id`**          | `integer`          | `not null, primary key`
# **`key_prefix`**  | `string(255)`      |
# **`name`**        | `string(255)`      | `not null`
# **`created_at`**  | `datetime`         | `not null`
# **`updated_at`**  | `datetime`         | `not null`
#
ActiveAdmin.register FundingBody do
  menu :parent => "Other Entities"
  config.sort_order = "name_asc"

  permit_params :key_prefix, :name

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
