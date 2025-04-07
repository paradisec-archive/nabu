# ## Schema Information
#
# Table name: `entities(VIEW)`
#
# ### Columns
#
# Name                  | Type               | Attributes
# --------------------- | ------------------ | ---------------------------
# **`entity_type`**     | `string(10)`       | `default(""), not null`
# **`essences_count`**  | `bigint`           | `default(0), not null`
# **`identifier`**      | `string(255)`      |
# **`items_count`**     | `bigint`           | `default(0), not null`
# **`private`**         | `integer`          |
# **`title`**           | `string(255)`      |
# **`entity_id`**       | `integer`          | `default(0), not null`
#
class Entity < ApplicationRecord
  belongs_to :entity, polymorphic: true

  def readonly?
    true
  end
end
