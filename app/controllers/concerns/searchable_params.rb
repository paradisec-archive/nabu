require 'active_support/concern'

# Single source of truth for advanced-search parameter allowlists. Used by:
#   - CollectionsController#advanced_search_params
#   - ItemsController#advanced_search_params
#   - HasReturnToLastSearch (session-stored search state)
#
# Keys are derived from the corresponding advanced_search.html.haml form fields,
# plus pagination/sort/format controls and CSV export flags. If a new search
# field is added to a form, also add it here or the value will be silently
# dropped on the server.
module SearchableParams
  extend ActiveSupport::Concern

  PAGINATION_KEYS = %i[
    page per_page start_page sort direction format export_all
  ].freeze

  GEO_KEYS = %i[north_limit south_limit east_limit west_limit].freeze

  COLLECTION_SEARCH_KEYS = (
    PAGINATION_KEYS + GEO_KEYS + %i[
      search
      identifier
      title title_blank
      description description_blank
      collector_id operator_id university_id
      collector_name
      countries content_languages
      region region_blank
      access_condition_id
      access_narrative access_narrative_blank
      complete private deposit_form_received
      metadata_source metadata_source_blank
      orthographic_notes orthographic_notes_blank
      media media_blank
      comments comments_blank
      tape_location tape_location_blank
      created_at created_at_blank
      updated_at updated_at_blank
      field_of_research_id funding_body_id
    ] + [{ country_ids: [], language_ids: [], admin_ids: [] }]
  ).freeze

  ITEM_SEARCH_KEYS = (
    PAGINATION_KEYS + GEO_KEYS + %i[
      search
      identifier full_identifier
      title title_blank
      description description_blank
      originated_on originated_on_blank
      originated_on_narrative originated_on_narrative_blank
      external private metadata_exportable born_digital tapes_returned no_files
      url url_blank
      collector_id operator_id
      collector_name
      countries content_languages
      language language_blank
      dialect dialect_blank
      region region_blank
      university_id
      discourse_type_id
      original_media original_media_blank
      received_on received_on_blank
      digitised_on digitised_on_blank
      ingest_notes ingest_notes_blank
      metadata_imported_on metadata_imported_on_blank
      metadata_exported_on metadata_exported_on_blank
      tracking tracking_blank
      created_at created_at_blank
      updated_at updated_at_blank
      access_condition_id
      access_narrative access_narrative_blank
      admin_comment admin_comment_blank
      filename mimetype framesPerSecond samplerate channels
    ] + [
      {
        country_ids: [],
        subject_language_ids: [],
        content_language_ids: [],
        data_category_ids: [],
        data_type_ids: [],
        agent_ids: [],
        admin_ids: [],
        user_ids: [],
        exclusions: []
      }
    ]
  ).freeze
end
