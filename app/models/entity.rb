# ## Schema Information
#
# Table name: `entities`
# Database name: `primary`
#
# ### Columns
#
# Name                  | Type               | Attributes
# --------------------- | ------------------ | ---------------------------
# **`id`**              | `bigint`           | `not null, primary key`
# **`entity_type`**     | `string(255)`      | `not null`
# **`essences_count`**  | `integer`          | `default(0), not null`
# **`items_count`**     | `integer`          | `default(0), not null`
# **`media_types`**     | `string(1000)`     |
# **`member_of`**       | `string(255)`      |
# **`originated_on`**   | `date`             |
# **`private`**         | `boolean`          | `default(FALSE), not null`
# **`title`**           | `string(255)`      |
# **`created_at`**      | `datetime`         | `not null`
# **`updated_at`**      | `datetime`         | `not null`
# **`entity_id`**       | `integer`          | `not null`
#
# ### Indexes
#
# * `index_entities_on_entity_type_and_entity_id` (_unique_):
#     * **`entity_type`**
#     * **`entity_id`**
# * `index_entities_on_entity_type_and_member_of`:
#     * **`entity_type`**
#     * **`member_of`**
# * `index_entities_on_member_of`:
#     * **`member_of`**
#
class Entity < ApplicationRecord
  belongs_to :entity, polymorphic: true

  validates :entity_type, presence: true
  validates :entity_id, presence: true, uniqueness: { scope: :entity_type }

  # NOTE: Only exist for abilities
  has_one :collection, foreign_key: :id, primary_key: :entity_id
  has_one :item, foreign_key: :id, primary_key: :entity_id
  has_one :essence, foreign_key: :id, primary_key: :entity_id
end
