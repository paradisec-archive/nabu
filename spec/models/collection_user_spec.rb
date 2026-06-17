# ## Schema Information
#
# Table name: `collection_users`
# Database name: `primary`
#
# ### Columns
#
# Name                 | Type               | Attributes
# -------------------- | ------------------ | ---------------------------
# **`id`**             | `integer`          | `not null, primary key`
# **`collection_id`**  | `integer`          | `not null`
# **`user_id`**        | `integer`          | `not null`
#
# ### Indexes
#
# * `index_collection_users_on_collection_id`:
#     * **`collection_id`**
# * `index_collection_users_on_collection_id_and_user_id` (_unique_):
#     * **`collection_id`**
#     * **`user_id`**
# * `index_collection_users_on_user_id`:
#     * **`user_id`**
#
require 'rails_helper'
require Rails.root.join 'spec/concerns/rejects_contact_grants_spec.rb'

describe CollectionUser, type: :model do
  it_behaves_like 'rejects contact grants', :collection
end
