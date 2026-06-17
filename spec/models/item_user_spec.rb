# ## Schema Information
#
# Table name: `item_users`
# Database name: `primary`
#
# ### Columns
#
# Name           | Type               | Attributes
# -------------- | ------------------ | ---------------------------
# **`id`**       | `integer`          | `not null, primary key`
# **`item_id`**  | `integer`          | `not null`
# **`user_id`**  | `bigint`           | `not null`
#
# ### Indexes
#
# * `index_item_users_on_item_id_and_user_id` (_unique_):
#     * **`item_id`**
#     * **`user_id`**
# * `index_item_users_on_user_id`:
#     * **`user_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`item_id => items.id`**
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`user_id => users.id`**
#
require 'rails_helper'
require Rails.root.join 'spec/concerns/rejects_contact_grants_spec.rb'

describe ItemUser, type: :model do
  it_behaves_like 'rejects contact grants', :item
end
