require 'oai/provider'

# TODO: Send these patches upstream in some way
module RecordResponseExtensions
  private
  # We don't want to use database ids for the identifier
  def identifier_for(record)
    "#{provider.prefix}:#{record.full_identifier}"
  end

  protected

  def valid?
    validate_identifier
  #   validate_dates
  #   validate_granularity
    super
  end

  def validate_identifier
    return if @options[:identifier].nil?

    if @options[:identifier] !~ /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[\-;:&=\+\$,\w]+@)?[A-Za-z0-9\.\-]+|(?:www\.|[\-;:&=\+\$,\w]+@)[A-Za-z0-9\.\-]+)((?:\/[\+~%\/\.\w\-_]*)?\??(?:[\-\+=&;%@\.\w_]*)#?(?:[\.\!\/\\\w]*))?)/
      raise OAI::ArgumentException.new
    end
  end

  # def validate_dates(params)
  #   if params["from"]
  #     raise OAI::ArgumentException.new if Timeliness.parse(params["from"]) == nil
  #   end
  #
  #   if params["until"]
  #     raise OAI::ArgumentException.new if Timeliness.parse(params["until"]) == nil
  #   end
  # end
  #
  # def validate_granularity(params)
  #   if params["from"] && params["until"]
  #     from_parse_result = begin
  #                          Time.iso8601(params["from"])
  #                        rescue ArgumentError
  #                          :parse_failure
  #                        end
  #
  #     from_parse_result = :parsed_correctly if from_parse_result.is_a?(Time)
  #
  #     until_parse_result = begin
  #                          Time.iso8601(params["until"])
  #                        rescue ArgumentError
  #                          :parse_failure
  #                        end
  #
  #     until_parse_result = :parsed_correctly if until_parse_result.is_a?(Time)
  #
  #     unless from_parse_result == until_parse_result
  #       raise OAI::ArgumentException.new
  #     end
  #   end
  # end
end

module OAI::Provider::Response
  class Base
    private

    # We need to convert the identifiers back to database IDs
    def extract_identifier(id)
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

  class RecordResponse < Base
    prepend RecordResponseExtensions
  end
end
