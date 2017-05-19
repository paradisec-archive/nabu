module ItemQueryBuilder
  # used by the front-end to provide a relevant input mechanism for the selected field
  TYPES_FOR_FIELDS = {
      collection_id: 'collection',
      identifier: 'text',
      private: 'boolean',
      title: 'text',
      url: 'text',
      collector_id: 'autocomplete',
      university_id: 'collection',
      operator_id: 'autocomplete',
      description: 'text',
      originated_on: 'date',
      language: 'text',
      dialect: 'text',
      region: 'text',
      discourse_type_id: 'collection',
      access_condition_id: 'collection',
      access_narrative: 'text',
      created_at: 'date',
      updated_at: 'date',
      metadata_exportable: 'boolean',
      born_digital: 'boolean',
      tapes_returned: 'boolean',
      original_media: 'text',
      received_on: 'date',
      digitised_on: 'date',
      ingest_notes: 'text',
      metadata_imported_on: 'date',
      metadata_exported_on: 'date',
      tracking: 'text',
      admin_comment: 'comment',
      external: 'boolean',
      originated_on_narrative: 'text',
      north_limit: 'number',
      south_limit: 'number',
      west_limit: 'number',
      east_limit: 'number',
      doi: 'text',
      'countries.id' => 'autocomplete',
      'subject_languages.id' => 'autocomplete',
      'content_languages.id' => 'autocomplete',
      'data_categories.id' => 'autocomplete',
      'data_types.id' => 'autocomplete',
      'agents.id' => 'autocomplete',
      'admins.id' => 'autocomplete',
      'users.id' => 'autocomplete',
      'essences.filename' => 'text',
      'essences.mimetype' => 'autocomplete',
      'essences.fps' => 'number',
      'essences.samplerate' => 'number',
      'essences.channels' => 'number',
  }.with_indifferent_access

  OPERATORS = ['is', 'is_not', 'contains', 'does_not_contain', 'is_null', 'is_not_null', 'less_than', 'more_than']


  def sql_operator(operator, invert=false)
    case operator
      when 'is'
        return invert ? '!=' : '='
      when 'is_not'
        return invert ? '=' : '!='
      when 'contains'
        return invert ? 'not like' : 'like'
      when 'does_not_contain'
        return invert ? 'like' : 'not like'
      when 'is_null'
        return invert ? 'is not null' : 'is null'
      when 'is_not_null'
        return invert ? 'is null' : 'is not null'
      when 'less_than'
        return invert ? '>=' : '<'
      when 'more_than'
        return invert ? '<=' : '>'
    end
  end

  def build_query(params)
    clauses = params[:clause]
    page = params[:page] || 1
    per_page = params[:per_page] || -1

    results = Item
    joins = []
    query = []
    values = []
    clauses.each_pair do |_, clause|
      field = clause['field']
      if field.include?('.')
        join_name = field.split('.').first
        join_name = join_name.sub(/(?!essences)/, 'item_\1')
        field = field.sub(/(users|admins|agents).id/, 'item_\1.user_id')
        field = field.sub(/(.*languages).id/, 'item_\1.language_id')
        field = field.sub(/(.*countries).id/, 'item_\1.country_id')
        field = field.sub(/(.*data_categories).id/, 'item_\1.data_category_id')
        field = field.sub(/(.*data_types).id/, 'item_\1.data_type_id')
        joins.push join_name
      else
        join_name = nil
      end

      clause_operator = sql_operator(clause['operator'], clause['logic'] == 'NOT')
      is_negative = clause_operator.include?('not')
      clause_sql = "#{field} #{clause_operator}"

      if is_negative && join_name.present?
        inverse_operator = sql_operator(clause['operator'], false)
        clause_sql = "not exists (select id from #{join_name} where #{field} #{inverse_operator}"
      end

      input_value = clause['input']
      if input_value
        clause_sql += ' ?'

        if TYPES_FOR_FIELDS[field] == 'date'
          input_value = DateTime.parse(input_value).strftime('%Y-%m-%d')
        end

        value_sql = clause_operator.include?('like') ? "%#{input_value}%" : input_value
        value_sql = value_sql.sub('true', '1').sub('false', '0')
        values.push value_sql
      end

      if is_negative && join_name.present?
        clause_sql += ')'
      end

      if clause['logic']
        query.push "#{clause['logic'].sub('NOT', 'AND')} #{clause_sql}"
      else
        query.push clause_sql
      end
    end
    results = results.includes(joins.uniq).where(query.join(' '), *values)
    if params[:exclusions].present?
      exclusions = params[:exclusions].split(',')
      results = results.where('items.id not in (?)', exclusions)
    end
    results.page(page).per(per_page)
  end
end