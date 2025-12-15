module Entityable
  extend ActiveSupport::Concern

  included do
    has_one :entity, as: :entity, dependent: :destroy

    after_create :create_entity_record
    after_update :sync_entity_record
  end

  private

  def create_entity_record
    Entity.create!(entity_attributes)
  end

  def sync_entity_record
    return unless entity_sync_needed?

    if entity
      entity.update!(entity_attributes.except(:entity))
    else
      create_entity_record
    end
  end

  def entity_sync_needed?
    entity_sync_attributes.any? { |attr| saved_change_to_attribute?(attr) }
  end

  def entity_sync_attributes
    raise NotImplementedError, "#{self.class} must implement #entity_sync_attributes"
  end

  def entity_attributes
    raise NotImplementedError, "#{self.class} must implement #entity_attributes"
  end
end
