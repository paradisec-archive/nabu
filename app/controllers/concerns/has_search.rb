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
        per_page: params[:per_page] || 10,
        track: { user_id: current_user&.id, search_family: 'advanced' }
      )
    end
  end

  def model
    self.class.search_model
  end

  def user_filter
    return if current_user&.admin?

    user_filter = []

    params.delete(:private)
    user_filter.push(where_exact(:private, false))

    model.search_user_fields.each do |field|
      params.delete(field)
      # FIXME this is a dirty hack for M2M oauth apps with public only
      user_filter.push(where_exact(field, current_user.id)) if current_user.id.is_a?(Numeric)
    end

    user_filter
  end

  def filter
    filter = []
    filter.push({ bool: { should: user_filter } }) if user_filter&.any?
    filter += model.search_filter_fields.map { |name| where_exact(name, params[name]) if params[name].present? }.compact

    filter.push(where_geo) if params[:north_limit]

    filter
  end

  def range
    range = {}
    range_names = %i[created_at updated_at]
    range_names.each { |name| range[name] = build_range_date(params[name]) if params[name].present? }

    range[:essences_count] = { gt: value } if params[:no_files]

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
    body[:query][:must].push({ range: }) if range.any?

    body[:query][:bool][:filter][:bool][:must_not] = [{ ids: { values: params[:exclusions].split(',').map(&:to_i) } }] if params[:exclusions].present?

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

  def basic_search_where
    where = {}
    model.search_agg_fields.each do |field|
      where[field] = params[field] if params[field].present?
    end

    return where if current_user&.admin?

    where[:_or] = [{ private: false }]
    model.search_user_fields.each do |field|
      where[:_or].push({ field => current_user.id }) if current_user
    end

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

  def quoted_phrase?(term)
    term.start_with?('"') && term.end_with?('"') && term.length > 1
  end

  def extract_phrase(term)
    return term unless quoted_phrase?(term)

    term[1..-2]
  end

  def where_regexp(name, value)
    {
      regexp: {
        name => {
          value: ".*#{value}.*",
          flags: 'NONE'
        }
      }
    }
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
    return if params[:sort].blank?

    # TODO: Put this back if they want default search
    # use_default = params[:sort].nil? || model.search_model.sortable_columns.exclude?(params[:sort])
    # return model.search_model.sortable_columns[0, 2].map { |col| { col => 'asc' } } if use_default

    [{ params[:sort] => params[:direction] == 'desc' ? 'desc' : 'asc' }]
  end
end
# rubocop:enable Metrics/ModuleLength
