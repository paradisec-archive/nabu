require 'oai'

module OAI::Provider::Response
  class RecordResponse < Base
    private
    # TODO Make this overidable upstream
    def identifier_for(record)
      "#{provider.prefix}:#{record.full_identifier}"
    end

    def timestamp_for(record)
      record.send(provider.model.timestamp_field.split('.').last).utc.xmlschema
    end
  end

  class Base
    private
    def extract_identifier(id)
      Rails.logger.debug id
      full_identifier = id.sub(/#{provider.prefix}:/, '')
      if full_identifier =~ /-/
        collection_identifier, item_identifier = full_identifier.split(/-/)
        collection = Collection.where(:identifier => collection_identifier).first
        item = collection.items.where(:identifier => item_identifier).first
        item.id
      else
        collection = Collection.where(:identifier => full_identifier).first
        collection.id
      end
    end
  end
end

module OAI::Provider
  class ActiveRecordWrapper
    def earliest
      earliest_obj = model.find(:first, :order => "#{timestamp_field} asc")
      earliest_obj.nil? ? Time.at(0) : earliest_obj.send(timestamp_field.split('.').last)
    end

    def latest
      latest_obj = model.find(:first, :order => "#{timestamp_field} desc")
      latest_obj.nil? ? Time.now : latest_obj.send(timestamp_field.split('.').last)
    end

    # Request the next set in this sequence.
    def next_set(find_scope, token_string)
      raise OAI::ResumptionTokenException.new unless @limit

      token = ResumptionToken.parse(token_string)
      total = find_scope.count("#{model.table_name}.id", :conditions => token_conditions(token))

      if @limit < total
        select_partial(find_scope, token)
      else # end of result set
        find_scope.find(:all,
                        :conditions => token_conditions(token),
                        :limit => @limit, :order => "#{model.primary_key} asc")
      end
    end

    def token_conditions(token)
      last = token.last
      sql = sql_conditions token.to_conditions_hash

      return sql if 0 == last
      # Now add last id constraint
      sql.first << " AND #{model.table_name}.#{model.primary_key} > :id"
      sql.last[:id] = last

      return sql
    end

  end
end
