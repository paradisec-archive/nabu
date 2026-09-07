class LanguageEquivalent < ApplicationRecord
  EVIDENCE = %w[glottolog:iso glottolog:closest_iso chirila:iso chirila:glottocode name synonym].freeze

  belongs_to :language
  belongs_to :related_language, class_name: 'Language'

  before_validation :order_the_pair

  validates :language_id, uniqueness: { scope: :related_language_id }
  validate :two_different_languages
  validate :evidence_is_a_list_of_known_tags

  scope :involving, ->(language) { where(language_id: language).or(where(related_language_id: language)) }

  # A pair is undirected, so the lower id always goes first; that is what lets one unique index
  # reject the same pair written the other way round. A bulk writer skips the callback below, so
  # it has to order its own rows through here — the check constraint says so if it forgets.
  def self.ordered_pair(one_id, other_id)
    [one_id, other_id].minmax
  end

  private

  def order_the_pair
    return if language_id.blank? || related_language_id.blank?

    self.language_id, self.related_language_id = self.class.ordered_pair(language_id, related_language_id)
  end

  def two_different_languages
    return if language_id.blank? || language_id != related_language_id

    errors.add(:related_language_id, 'is the same language')
  end

  def evidence_is_a_list_of_known_tags
    unknown = Array(evidence) - EVIDENCE
    errors.add(:evidence, "has tags no seed produces: #{unknown.join(', ')}") if unknown.any?
    errors.add(:evidence, 'must say what the pair rests on') if Array(evidence).empty?
  end
end
