class ItemAnnotationsController < ApplicationController
  before_action :load_item

  def show
    @page_title = "Nabu - Annotation mappings for #{@item.title}"
    @transcripts = item_essences.select(&:annotation_extension?).sort_by { |e| e.filename.downcase }
    @media = item_essences.select(&:annotatable_extension?).sort_by { |e| e.filename.downcase }
    @existing_mappings = EssenceAnnotation
                          .where(annotation_essence_id: @transcripts.map(&:id))
                          .group_by(&:annotation_essence_id)
                          .transform_values { |rows| rows.map(&:target_essence_id).to_set }
  end

  def update
    submitted = params.fetch(:mappings, {}).to_unsafe_h

    EssenceAnnotation.transaction do
      submitted.each do |transcript_id, target_ids|
        transcript = @item.essences.find_by(id: transcript_id)
        next if transcript.nil?

        desired = Array(target_ids).map(&:to_i).reject(&:zero?).to_set
        current = transcript.outgoing_annotation_links.pluck(:target_essence_id).to_set

        (desired - current).each do |target_id|
          authorize_target!(target_id)
          EssenceAnnotation.create!(annotation_essence_id: transcript.id, target_essence_id: target_id)
        end

        (current - desired).each do |target_id|
          link = transcript.outgoing_annotation_links.find_by(target_essence_id: target_id)
          link&.destroy!
        end
      end
    end

    flash[:notice] = 'Annotation mappings updated.'
    redirect_to collection_item_annotations_path(@collection, @item)
  end

  private

  def load_item
    @collection = Collection.find_by!(identifier: params[:collection_id])
    @item = @collection.items.find_by!(identifier: params[:item_id])
    authorize! :update, @item
  end

  def item_essences
    @item_essences ||= @item.essences.includes(:outgoing_annotation_links).to_a
  end

  def authorize_target!(target_id)
    target = @item.essences.find_by(id: target_id)
    raise CanCan::AccessDenied if target.nil?
  end
end
