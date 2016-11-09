module OAI::Provider
  class Base
    include OAI::Provider

    class << self
      attr_reader :formats
      attr_accessor :name, :url, :prefix, :email, :delete_support, :granularity, :model, :identifier, :description

      def register_format(format)
        @formats ||= {}
        @formats[format.prefix] = format
      end

      def format_supported?(prefix)
        @formats.keys.include?(prefix)
      end

      def format(prefix)
        if @formats[prefix].nil?
          raise OAI::FormatException.new
        else
          @formats[prefix]
        end
      end

      protected

      def inherited(klass)
        self.instance_variables.each do |iv|
          klass.instance_variable_set(iv, self.instance_variable_get(iv))
        end
      end

      alias_method :repository_name,    :name=
      alias_method :repository_url,     :url=
      alias_method :record_prefix,      :prefix=
      alias_method :admin_email,        :email=
      alias_method :deletion_support,   :delete_support=
      alias_method :update_granularity, :granularity=
      alias_method :source_model,       :model=
      alias_method :sample_id,          :identifier=
      alias_method :extra_description,  :description=

    end

    # Default configuration of a repository
    Base.repository_name 'Open Archives Initiative Data Provider'
    Base.repository_url 'unknown'
    Base.record_prefix 'oai:localhost'
    Base.admin_email 'nobody@localhost'
    Base.deletion_support OAI::Const::Delete::TRANSIENT
    Base.update_granularity OAI::Const::Granularity::HIGH
    Base.sample_id '13900'

    Base.register_format(OAI::Provider::Metadata::DublinCore.instance)

    # Equivalent to '&verb=Identify', returns information about the repository
    def identify(options = {})
      Response::Identify.new(self.class, options).to_xml
    end

    # Equivalent to '&verb=ListSets', returns a list of sets that are supported
    # by the repository or an error if sets are not supported.
    def list_sets(options = {})
      Response::ListSets.new(self.class, options).to_xml
    end

    # Equivalent to '&verb=ListMetadataFormats', returns a list of metadata formats
    # supported by the repository.
    def list_metadata_formats(options = {})
      Response::ListMetadataFormats.new(self.class, options).to_xml
    end

    # Equivalent to '&verb=ListIdentifiers', returns a list of record headers that
    # meet the supplied criteria.
    def list_identifiers(options = {})
      Response::ListIdentifiers.new(self.class, options).to_xml
    end

    # Equivalent to '&verb=ListRecords', returns a list of records that meet the
    # supplied criteria.
    def list_records(options = {})
      Response::ListRecords.new(self.class, options).to_xml
    end

    # Equivalent to '&verb=GetRecord', returns a record matching the required
    # :identifier option
    def get_record(options = {})
      Response::GetRecord.new(self.class, options).to_xml
    end

    #  xml_response = process_verb('ListRecords', :from => 'October 1, 2005',
    #    :until => 'November 1, 2005')
    #
    # If you are implementing a web interface using process_request is the
    # preferred way.
    def process_request(params = {})
      begin
        validate_identifier(params)
        validate_dates(params)
        validate_granularity(params)

        # Allow the request to pass in a url
        self.class.url = params['url'] ? params.delete('url') : self.class.url

        verb = params.delete('verb') || params.delete(:verb)

        unless verb and OAI::Const::VERBS.keys.include?(verb)
          raise OAI::VerbException.new
        end

        send(methodize(verb), params)

      rescue => err
        if err.respond_to?(:code)
          Response::Error.new(self.class, err).to_xml
        else
          raise err
        end
      end
    end

    def validate_identifier(params)
      if params["identifier"] && params["identifier"] !~ /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[\-;:&=\+\$,\w]+@)?[A-Za-z0-9\.\-]+|(?:www\.|[\-;:&=\+\$,\w]+@)[A-Za-z0-9\.\-]+)((?:\/[\+~%\/\.\w\-_]*)?\??(?:[\-\+=&;%@\.\w_]*)#?(?:[\.\!\/\\\w]*))?)/
        raise OAI::ArgumentException.new
      end
    end

    def validate_dates(params)
      if params["from"]
        raise OAI::ArgumentException.new if Timeliness.parse(params["from"]) == nil
      end

      if params["until"]
        raise OAI::ArgumentException.new if Timeliness.parse(params["until"]) == nil
      end
    end

    def validate_granularity(params)
      if params["from"] && params["until"]
        from_parse_result = begin
                             Time.iso8601(params["from"])
                           rescue ArgumentError
                             :parse_failure
                           end

        from_parse_result = :parsed_correctly if from_parse_result.is_a?(Time)

        until_parse_result = begin
                             Time.iso8601(params["until"])
                           rescue ArgumentError
                             :parse_failure
                           end

        until_parse_result = :parsed_correctly if until_parse_result.is_a?(Time)

        unless from_parse_result == until_parse_result
          raise OAI::ArgumentException.new
        end
      end
    end

    # Convert valid OAI-PMH verbs into ruby method calls
    def methodize(verb)
      verb.gsub(/[A-Z]/) {|m| "_#{m.downcase}"}.sub(/^\_/,'')
    end
  end
end
