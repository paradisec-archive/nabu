require 'oai'

class CollectionProvider < ApplicationProvider
  repository_url 'http://catalog.paradisec.org.au/oai/collection'
  sample_id '13900'

  source_model OAI::Provider::ActiveRecordWrapper.new(
    ::Collection.where(:private => false).includes(:access_condition, :collector, :university, :languages, :field_of_research, :countries, :items, grants: [:funding_body]),
    :limit => 100
  )

  class << self
    def formats
      @filtered_formats ||= @formats.slice('oai_dc', 'rif')
    end
  end
end
