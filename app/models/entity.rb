# ## Schema Information
#
# Table name: `entities(VIEW)`
#
# ### Columns
#
# Name                         | Type               | Attributes
# ---------------------------- | ------------------ | ---------------------------
# **`collection_identifier`**  | `string(255)`      |
# **`entity_type`**            | `string(10)`       | `default(""), not null`
# **`essences_count`**         | `bigint`           | `default(0), not null`
# **`items_count`**            | `bigint`           | `default(0), not null`
# **`private`**                | `integer`          |
# **`entity_id`**              | `integer`          | `default(0), not null`
#
class Entity < ApplicationRecord
  belongs_to :entity, polymorphic: true

  def readonly?
    true
  end
end
