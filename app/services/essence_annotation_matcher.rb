# Auto-creates default EssenceAnnotation links for a newly created essence by matching
# basenames (case-insensitively) against opposite-class siblings in the same item.
#
# Transcripts (ANNOTATION_EXTENSIONS) link to existing media; media (ANNOTATABLE_EXTENSIONS)
# created later link back to existing transcripts. All matches are linked, and the operation
# is idempotent (find_or_create_by against the unique pair index). Matching failures never
# break ingest: they are rescued, logged, and reported to Sentry.
class EssenceAnnotationMatcher
  def self.link_for(essence)
    new(essence).link
  end

  def initialize(essence)
    @essence = essence
  end

  def link
    if @essence.annotation_extension?
      matching_siblings(&:annotatable_extension?).each { |media| create_link(@essence, media) }
    elsif @essence.annotatable_extension?
      matching_siblings(&:annotation_extension?).each { |transcript| create_link(transcript, @essence) }
    end
  rescue StandardError => e
    # Guards against a failure in the sibling lookup itself; per-pair failures are handled below.
    report(e)
  end

  private

  # A transcript always sits on the annotation side, media on the target side.
  #
  # Each pair is linked independently and rescued on its own: one failing link must never abort
  # the remaining valid matches (nor break ingest). find_or_create_by is not atomic, so a
  # concurrent creation of the same pair raises RecordNotUnique - that just means the pair we
  # wanted already exists, which is the desired end state, so we treat it as success.
  def create_link(transcript, media)
    EssenceAnnotation.find_or_create_by!(annotation_essence: transcript, target_essence: media)
  rescue ActiveRecord::RecordNotUnique
    nil
  rescue StandardError => e
    report(e)
  end

  def report(error)
    Rails.logger.error("[EssenceAnnotationMatcher] Failed to link essence #{@essence.id}: #{error.message}")
    Sentry.capture_exception(error, extra: { essence_id: @essence.id, item_id: @essence.item_id }) if defined?(Sentry)
  end

  def matching_siblings(&predicate)
    @essence.item.essences
            .where.not(id: @essence.id)
            .select { |sibling| predicate.call(sibling) && sibling.basename == @essence.basename }
  end
end
