# ## Schema Information
#
# Table name: `items`
# Database name: `primary`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`id`**                       | `integer`          | `not null, primary key`
# **`access_narrative`**         | `text(16777215)`   |
# **`admin_comment`**            | `text(16777215)`   |
# **`born_digital`**             | `boolean`          |
# **`description`**              | `text(16777215)`   | `not null`
# **`dialect`**                  | `string(255)`      |
# **`digitised_on`**             | `datetime`         |
# **`doi`**                      | `string(255)`      |
# **`east_limit`**               | `float(24)`        |
# **`essences_count`**           | `integer`          |
# **`external`**                 | `boolean`          | `default(FALSE)`
# **`identifier`**               | `string(255)`      | `not null`
# **`ingest_notes`**             | `text(16777215)`   |
# **`language`**                 | `string(255)`      |
# **`metadata_exportable`**      | `boolean`          |
# **`metadata_exported_on`**     | `datetime`         |
# **`metadata_imported_on`**     | `datetime`         |
# **`north_limit`**              | `float(24)`        |
# **`original_media`**           | `text(16777215)`   |
# **`originated_on`**            | `date`             |
# **`originated_on_narrative`**  | `text(16777215)`   |
# **`private`**                  | `boolean`          |
# **`received_on`**              | `datetime`         |
# **`region`**                   | `string(255)`      |
# **`south_limit`**              | `float(24)`        |
# **`tapes_returned`**           | `boolean`          |
# **`title`**                    | `string(255)`      | `not null`
# **`tracking`**                 | `text(16777215)`   |
# **`url`**                      | `string(255)`      |
# **`west_limit`**               | `float(24)`        |
# **`created_at`**               | `datetime`         | `not null`
# **`updated_at`**               | `datetime`         | `not null`
# **`access_condition_id`**      | `integer`          |
# **`collection_id`**            | `integer`          | `not null`
# **`collector_id`**             | `integer`          | `not null`
# **`discourse_type_id`**        | `integer`          |
# **`operator_id`**              | `integer`          |
# **`university_id`**            | `integer`          |
#
# ### Indexes
#
# * `index_items_on_access_condition_id`:
#     * **`access_condition_id`**
# * `index_items_on_collection_id`:
#     * **`collection_id`**
# * `index_items_on_collection_id_and_private_and_updated_at`:
#     * **`collection_id`**
#     * **`private`**
#     * **`updated_at`**
# * `index_items_on_collector_id`:
#     * **`collector_id`**
# * `index_items_on_discourse_type_id`:
#     * **`discourse_type_id`**
# * `index_items_on_identifier_and_collection_id` (_unique_):
#     * **`identifier`**
#     * **`collection_id`**
# * `index_items_on_operator_id`:
#     * **`operator_id`**
# * `index_items_on_university_id`:
#     * **`university_id`**
#

require 'rails_helper'
require Rails.root.join "spec/concerns/identifiable_by_doi_spec.rb"

describe Item, type: :model do
  include_examples "identifiable by doi", "collection"
end
