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
        per_page: params[:per_page] || 10,
        track: { user_id: current_user&.id, search_family: 'basic' },

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
      user_filter.push(where_exact(field, current_user.id))
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
    text = model.search_text_fields.map { |name| build_should(name, params[name]) if params[name].present? }.compact

    body = {
      query: {
        bool: {
          must: [
            { bool: { should: text } }
          ],
          filter: {
            bool: { must: filter }
          }
        }
      }
    }
    body[:query][:must].push({ range: }) if range.any?

    body[:query][:bool][:filter][:bool][:must_not] = [{ ids: { values: params[:exclusions].split(',').map(&:to_i) } }] if params[:exclusions].present?

    body[:order] = order if order

    body
  end

  # rubocop:disable Metrics/MethodLength
  def build_should(name, value)
    boost = case name
    when :title then 10
    when :identifier then 20
    else 1
    end

    {
      dis_max: {
        queries: [
          {
            bool: {
              must: {
                bool: {
                  should: [
                    { match: { "#{name}.word_start": { query: value, boost: boost * 10, operator: 'and', analyzer: 'searchkick_word_search' } } }
                    # { match: { "#{name}.word_start": { query: value, boost:, operator: 'and', analyzer: 'searchkick_word_search', fuzziness: 1,
                    #                                    prefix_length: 0, max_expansions: 3, fuzzy_transpositions: true } } }
                  ]
                }
              },
              should: {
                match: { "#{name}.analyzed": { query: value, boost: boost * 10, operator: 'and', analyzer: 'searchkick_word_search' } }
              }
            }
          }
        ]
      }
    }
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
      term: {
        name => {
          value:
        }
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
