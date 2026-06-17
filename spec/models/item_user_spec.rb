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
# **`user_id`**  | `integer`          | `not null`
#
# ### Indexes
#
# * `index_item_users_on_item_id_and_user_id` (_unique_):
#     * **`item_id`**
#     * **`user_id`**
#
require 'rails_helper'
require Rails.root.join 'spec/concerns/rejects_contact_grants_spec.rb'

describe ItemUser, type: :model do
  it_behaves_like 'rejects contact grants', :item
end
