# ## Schema Information
#
# Table name: `language_equivalents`
# Database name: `primary`
#
# ### Columns
#
# Name                       | Type               | Attributes
# -------------------------- | ------------------ | ---------------------------
# **`id`**                   | `bigint`           | `not null, primary key`
# **`evidence`**             | `json`             | `not null`
# **`language_id`**          | `integer`          | `not null`
# **`related_language_id`**  | `integer`          | `not null`
#
# ### Indexes
#
# * `index_language_equivalents_on_pair` (_unique_):
#     * **`language_id`**
#     * **`related_language_id`**
# * `index_language_equivalents_on_related_language_id`:
#     * **`related_language_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...`:
#     * **`language_id => languages.id`**
# * `fk_rails_...`:
#     * **`related_language_id => languages.id`**
#
class LanguageEquivalent < ApplicationRecord
  # Every kind of evidence a pair can rest on, strongest first, each against what a chip says for
  # itself on hover. Nabu asserts no confidence beyond naming where the pairing came from.
  EVIDENCE = {
    'glottolog:iso' => 'Glottolog gives this ISO 639-3 code',
    'glottolog:closest_iso' => 'Glottolog names this the closest ISO 639-3 code',
    'chirila:iso' => 'Chirila pairs these by ISO 639-3 code',
    'chirila:glottocode' => 'Chirila pairs these by glottocode',
    'name' => 'Both Sources publish the same name'
  }.freeze

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

  # What each of these Languages could be offered alongside, keyed by the Language the chips hang
  # under, strongest evidence first.
  #
  # A chip adds a Language the picker was never asked for, so each option carries that Language's own
  # Equivalents and its chips render in turn. One level deep and no further: A paired with B and B
  # with C is two pairs, each its own click, and never a pairing of A with C.
  def self.options_for(languages, nested: true)
    return {} if languages.empty?

    pairs = involving(languages.map(&:id)).includes(:language, :related_language).sort_by { |pair| [pair.evidence_rank, pair.id] }
    offered = nested ? options_for(pairs.flat_map { |pair| [pair.language, pair.related_language] }.uniq - languages, nested: false) : {}

    languages.index_by(&:id).transform_values do |language|
      pairs.select { |pair| pair.involves?(language) }.map { |pair| pair.option_for(language, offered) }
    end
  end

  def involves?(this_language)
    [language_id, related_language_id].include?(this_language.id)
  end

  def other_than(this_language)
    language_id == this_language.id ? related_language : language
  end

  def option_for(this_language, offered = {})
    other = other_than(this_language)

    other.picker_option(offered[other.id]).merge(reason: EVIDENCE[top_evidence])
  end

  # The fixed order evidence is read in, strongest first, wherever a pair's tags are held or shown.
  def self.sort_evidence(tags)
    tags.sort_by { |tag| evidence_order(tag) }
  end

  def self.evidence_order(tag)
    EVIDENCE.keys.index(tag) || EVIDENCE.size
  end

  def sorted_evidence
    self.class.sort_evidence(Array(evidence))
  end

  def top_evidence
    sorted_evidence.first
  end

  def evidence_rank
    self.class.evidence_order(top_evidence)
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
    unknown = Array(evidence) - EVIDENCE.keys
    errors.add(:evidence, "has tags no seed produces: #{unknown.join(', ')}") if unknown.any?
    errors.add(:evidence, 'must say what the pair rests on') if Array(evidence).empty?
  end
end
