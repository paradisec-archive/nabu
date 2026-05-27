# ## Schema Information
#
# Table name: `essence_annotations`
# Database name: `primary`
#
# ### Columns
#
# Name                         | Type               | Attributes
# ---------------------------- | ------------------ | ---------------------------
# **`id`**                     | `bigint`           | `not null, primary key`
# **`created_at`**             | `datetime`         | `not null`
# **`updated_at`**             | `datetime`         | `not null`
# **`annotation_essence_id`**  | `integer`          | `not null`
# **`target_essence_id`**      | `integer`          | `not null`
#
# ### Indexes
#
# * `index_essence_annotations_on_annotation_essence_id`:
#     * **`annotation_essence_id`**
# * `index_essence_annotations_on_target_essence_id`:
#     * **`target_essence_id`**
# * `index_essence_annotations_unique_pair` (_unique_):
#     * **`annotation_essence_id`**
#     * **`target_essence_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`annotation_essence_id => essences.id`**
# * `fk_rails_...` (_ON DELETE => cascade_):
#     * **`target_essence_id => essences.id`**
#
class EssenceAnnotation < ApplicationRecord
  has_paper_trail

  belongs_to :annotation_essence, class_name: 'Essence'
  belongs_to :target_essence, class_name: 'Essence'

  validates :annotation_essence_id, uniqueness: { scope: :target_essence_id }
  validate :essences_share_item
  validate :annotation_extension_allowed
  validate :target_extension_allowed

  after_commit :refresh_catalog_metadata, on: %i[create destroy]

  private

  def essences_share_item
    return if annotation_essence.nil? || target_essence.nil?
    return if annotation_essence.item_id == target_essence.item_id

    errors.add(:base, 'must annotate an essence in the same item')
  end

  def annotation_extension_allowed
    return if annotation_essence.nil?
    return if annotation_essence.annotation_extension?

    errors.add(:annotation_essence, "must be a transcript file (#{Essence::ANNOTATION_EXTENSIONS.join(', ')})")
  end

  def target_extension_allowed
    return if target_essence.nil?
    return if target_essence.annotatable_extension?

    errors.add(:target_essence, "must be a media file (#{Essence::ANNOTATABLE_EXTENSIONS.join(', ')})")
  end

  def refresh_catalog_metadata
    target_essence&.item&.update_catalog_metadata
  end
end
