# ## Schema Information
#
# Table name: `collections`
#
# ### Columns
#
# Name                         | Type               | Attributes
# ---------------------------- | ------------------ | ---------------------------
# **`id`**                     | `integer`          | `not null, primary key`
# **`access_narrative`**       | `text(16777215)`   |
# **`comments`**               | `text(16777215)`   |
# **`complete`**               | `boolean`          |
# **`deposit_form_received`**  | `boolean`          |
# **`description`**            | `text(16777215)`   | `not null`
# **`doi`**                    | `string(255)`      |
# **`east_limit`**             | `float(24)`        |
# **`identifier`**             | `string(255)`      | `not null`
# **`media`**                  | `string(255)`      |
# **`metadata_source`**        | `string(255)`      |
# **`north_limit`**            | `float(24)`        |
# **`orthographic_notes`**     | `string(255)`      |
# **`private`**                | `boolean`          |
# **`region`**                 | `string(255)`      |
# **`south_limit`**            | `float(24)`        |
# **`tape_location`**          | `string(255)`      |
# **`title`**                  | `string(255)`      | `not null`
# **`west_limit`**             | `float(24)`        |
# **`created_at`**             | `datetime`         | `not null`
# **`updated_at`**             | `datetime`         | `not null`
# **`access_condition_id`**    | `integer`          |
# **`collector_id`**           | `integer`          | `not null`
# **`field_of_research_id`**   | `integer`          |
# **`operator_id`**            | `integer`          |
# **`university_id`**          | `integer`          |
#
# ### Indexes
#
# * `index_collections_on_access_condition_id`:
#     * **`access_condition_id`**
# * `index_collections_on_collector_id`:
#     * **`collector_id`**
# * `index_collections_on_field_of_research_id`:
#     * **`field_of_research_id`**
# * `index_collections_on_identifier` (_unique_):
#     * **`identifier`**
# * `index_collections_on_operator_id`:
#     * **`operator_id`**
# * `index_collections_on_university_id`:
#     * **`university_id`**
#
require 'rails_helper'
require Rails.root.join "spec/concerns/identifiable_by_doi_spec.rb"

describe Collection, type: :model do
  include_examples "identifiable by doi"
end
