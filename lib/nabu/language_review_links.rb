# frozen_string_literal: true

module Nabu
  # Edit links for every collection and item still attached to a language, for manual reassignment after a retirement
  class LanguageReviewLinks
    include Enumerable

    def initialize(language)
      @language = language
    end

    def each(&)
      lines.each(&)
    end

    private

    def lines
      collections = Collection.where(id: CollectionLanguage.where(language_id: @language.id).select(:collection_id))
      item_ids = ItemContentLanguage.where(language_id: @language.id).select(:item_id)
      subject_item_ids = ItemSubjectLanguage.where(language_id: @language.id).select(:item_id)
      items = Item.where(id: item_ids).or(Item.where(id: subject_item_ids))

      collection_lines = collections.order(:identifier).map { |c| "  #{c.identifier}: #{helpers.edit_collection_url(c, **url_options)}" }
      item_lines = items.includes(:collection).order(:collection_id, :identifier).map do |i|
        "  #{i.full_identifier}: #{helpers.edit_collection_item_url(i.collection, i, **url_options)}"
      end

      collection_lines + item_lines
    end

    def helpers
      Rails.application.routes.url_helpers
    end

    def url_options
      host = Rails.application.config.action_mailer.default_url_options&.dig(:host) || 'catalog.paradisec.org.au'
      { host:, protocol: 'https' }
    end
  end
end
