GraphiQL::Rails.config.initial_query = <<-GRAPHQL
{
  items(limit: 100, page: 1) {
    total
    next_page
    results {
      full_identifier
      title
      description
      dialect
      language
      region
      originated_on
      originated_on_narrative
      collection {
        identifier
        title
      }
      collector {
        first_name
        last_name
        country
      }
      university {
        name
        party_identifier
      }
      discourse_type {
        name
      }
      data_types {
        name
      }
      data_categories {
        name
      }
      countries {
        name
        code
      }
      subject_languages {
        name
        code
      }
      content_languages {
        name
        code
      }
      access_class
      access_narrative
      citation
      ingest_notes
      original_media
      permalink
      doi
    }
  }
}
GRAPHQL
