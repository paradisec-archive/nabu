require 'active_support/concern'

# rubocop:disable Metrics/ModuleLength
module HasSearch
  extend ActiveSupport::Concern

  included do
    class_attribute :search_model, instance_accessor: false, instance_predicate: false

    private

    def create_aggs
      aggs = {}

      model.search_agg_fields.each do |field|
        if params[field]
          # Only show the selected filter in the dropdown
          aggs[field] = { where: { field => params[field] } }
        else
          aggs[field] = {}
        end
      end

      aggs
    end

    def build_basic_search
      @search = model.search(
        params[:search] || '*',
        includes: model.search_includes,
        fields: [
          { 'full_identifier^20': :word_start },
          { 'identifier^20': :word_start },
          'title^10',
          'description',
          '*'
        ],

        aggs: create_aggs,

        where: basic_search_where,

        order:,
        page: params[:page],
        per_page: (params[:export_all] && 5000) || params[:per_page] || 10,
        track: params[:search].blank? ? nil : { user_id: current_user&.id, search_family: 'basic' },

        misspellings: false
      )
    end

    def build_advanced_search
      @search = model.search(
        body:,
        includes: model.search_includes,

        page: params[:page],
        per_page: (params[:export_all] && 5000) || params[:per_page] || 10,
        track: { user_id: current_user&.id, search_family: 'advanced' }
      )
    end
  end

  def model
    self.class.search_model
  end

  # Single source of truth for "which documents may current_user see" in search.
  #
  # Returns :all for admins (no restriction), otherwise a list of alternative match clauses
  # with OR semantics: a document is visible if it is public OR current_user is in the document's
  # access_user_ids union (the deduped set of everyone-who-can-read). This mirrors the :read grants
  # in app/models/ability.rb - model.search_user_fields is the denormalised mirror of those grants.
  #
  # Both search families consume this one method so they cannot drift: the basic search
  # (Searchkick `where`, via basic_search_where) and the advanced search (raw OpenSearch
  # `body`, via user_filter). spec/features/search_authorisation_consistency_spec.rb pins the
  # result of this filtering to Ability for every read path.
  def visibility_clauses
    return :all if current_user&.admin?

    clauses = [{ private: false }]
    if user_id_filterable?
      model.search_user_fields.each { |field| clauses << { field => current_user.id } }
    end

    clauses
  end

  # Non-numeric ids belong to M2M OAuth apps, which only ever get public records.
  def user_id_filterable?
    current_user&.id.is_a?(Numeric)
  end

  # Advanced search (raw OpenSearch body) adapter for visibility_clauses.
  def user_filter
    clauses = visibility_clauses
    return if clauses == :all

    # Strip any user-supplied permission params so they cannot widen their own visibility.
    params.delete(:private)
    model.search_user_fields.each { |field| params.delete(field) }

    clauses.map { |clause| where_exact(*clause.first) }
  end

  def filter
    filter = []
    should = user_filter
    filter.push({ bool: { should: } }) if should&.any?
    filter += model.search_filter_fields.map { |name| where_exact(name, params[name]) if params[name].present? }.compact

    filter.push(where_geo) if params[:north_limit]

    filter
  end

  def range
    range = {}
    range_names = %i[created_at updated_at]
    range_names.each { |name| range[name] = build_range_date(params[name]) if params[name].present? }

    range[:essences_count] = { lte: 0 } if params[:no_files]

    range
  end

  def body
    text = []
    model.search_text_fields.each do |name|
      next unless params[name].present?

      parsed = parse_search_terms(params[name])

      # Add exact phrase queries
      parsed[:exact_phrases].each do |phrase|
        text << build_should(name, phrase, exact: true)
      end

      # Add fuzzy term queries
      unless parsed[:fuzzy_terms].empty?
        fuzzy_query = parsed[:fuzzy_terms].join(' ')
        text << build_should(name, fuzzy_query, exact: false)
      end
    end

    body = {
      query: {
        bool: {
          must: [
            { bool: { must: text } }
          ]
        }
      }
    }

    body[:query][:bool][:filter] = { bool: { must: filter } } if filter.any?
    body[:query][:bool][:must].push({ range: }) if range.any?

    if params[:exclusions].present?
      body[:query][:bool][:filter] ||= { bool: {} }
      body[:query][:bool][:filter][:bool][:must_not] = [{ ids: { values: params[:exclusions].split(',').map(&:to_i) } }]
    end

    body[:sort] = order if order

    body
  end

  # rubocop:disable Metrics/MethodLength
  def build_should(name, value, exact: false)
    boost = case name
    when :title then 10
    when :identifier then 20
    else 1
    end

    if exact
      {
        dis_max: {
          queries: [
            {
              match_phrase: { "#{name}.analyzed": { query: value, boost: boost * 10 } }
            },
            {
              match_phrase: { name.to_s => { query: value, boost: boost * 5 } }
            }
          ]
        }
      }
    else
      {
        dis_max: {
          queries: [
            {
              bool: {
                should: [
                  {  match: { "#{name}.analyzed": { query: value, boost: boost * 10  } } }
                ]
              }
            }
          ]
        }
      }
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Basic search (Searchkick `where`) adapter for visibility_clauses.
  def basic_search_where
    where = {}
    model.search_agg_fields.each do |field|
      where[field] = params[field] if params[field].present?
    end

    clauses = visibility_clauses
    where[:_or] = clauses unless clauses == :all

    where
  end

  def parse_search_terms(value)
    return { exact_phrases: [], fuzzy_terms: [] } if value.blank?

    exact_phrases = []
    remaining_text = value.dup

    # Extract quoted phrases
    remaining_text.scan(/"([^"]*)"/) do |match|
      exact_phrases << match[0] unless match[0].blank?
    end

    # Remove quoted phrases from remaining text
    fuzzy_text = remaining_text.gsub(/"[^"]*"/, ' ').strip

    # Split remaining text into individual terms
    fuzzy_terms = fuzzy_text.split(/\s+/).reject(&:blank?)

    { exact_phrases:, fuzzy_terms: }
  end

  def where_exact(name, value)
    {
      terms: {
        name => value.is_a?(Array) ? value : [value]
      }
    }
  end

  def where_geo
    {
      geo_bounding_box: {
        bounds: {
          top_left: { lat: params[:north_limit], lon: params[:west_limit] },
          bottom_right: { lat: params[:south_limit], lon: params[:east_limit] }
        }
      }
    }
  end

  def build_range_date(value)
    from = Date.parse(value)
    to = from + 1
    {
      gte: from,
      lt: to
    }
  end

  def order
    direction = params[:direction] == 'desc' ? 'desc' : 'asc'

    # Only sort on whitelisted, indexed columns. An unknown sort field would otherwise
    # trigger an OpenSearch query_shard_exception ("No mapping found for [...]").
    sort = params[:sort].presence
    sort = nil unless sort && model.sortable_columns.include?(sort)

    return [{ sort_field('full_identifier') => direction }] if params[:search].blank? && sort.blank?

    return if sort.blank?

    [{ sort_field(sort) => direction }]
  end

  # Let a model remap a sort column to a different index field (e.g. a case-insensitive
  # variant). Models that don't define this sort on the column as-is.
  def sort_field(field)
    return model.search_sort_field(field) if model.respond_to?(:search_sort_field)

    field
  end
end
# rubocop:enable Metrics/ModuleLength
