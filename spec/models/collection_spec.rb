# ## Schema Information
#
# Table name: `collections`
# Database name: `primary`
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
# **`has_deposit_form`**       | `boolean`          |
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
# * `index_collections_on_private`:
#     * **`private`**
# * `index_collections_on_university_id`:
#     * **`university_id`**
#
require 'rails_helper'
require Rails.root.join "spec/concerns/identifiable_by_doi_spec.rb"

describe Collection, type: :model do
  it_behaves_like "identifiable by doi"

  describe 'identifier case validation', :no_catalog_upload do
    it 'accepts an all-uppercase identifier on create' do
      collection = build(:collection, identifier: 'ABC123')

      expect(collection).to be_valid
    end

    it 'rejects an identifier containing a lowercase letter on create' do
      collection = build(:collection, identifier: 'Abc123')

      aggregate_failures do
        expect(collection).not_to be_valid
        expect(collection.errors[:identifier]).to be_present
      end
    end

    it 'lets an existing mixed-case collection be saved (e.g. a title edit)' do
      collection = create(:collection)
      # Bypass the create-time validation to seed a legacy lowercase identifier.
      collection.update_column(:identifier, 'legacy')

      collection.title = 'A new title'

      expect(collection.save).to be(true)
    end
  end

  describe 'title length validation', :no_catalog_upload do
    it 'accepts a title at the 255 character column limit' do
      expect(build(:collection, title: 'a' * 255)).to be_valid
    end

    it 'rejects a title longer than the column allows rather than overflowing the DB' do
      collection = build(:collection, title: 'a' * 256)

      aggregate_failures do
        expect(collection).not_to be_valid
        expect(collection.errors[:title]).to be_present
      end
    end
  end
end
