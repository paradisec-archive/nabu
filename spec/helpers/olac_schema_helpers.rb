require 'nokogiri'

# Validates an OLAC record against the vendored OLAC 1.1 schemas. The schemas restrict olac:code to
# the ISO 639 shape, so this is what keeps a glottocode or an AUSTLANG code out of an ISO-typed
# attribute; see spec/support/schema/README.md for where the files came from.
module OlacSchemaHelpers
  OLAC_SCHEMA_PATH = Rails.root.join('spec/support/schema/olac.xsd').freeze
  OLAC_NAMESPACE = 'http://www.language-archives.org/OLAC/1.1/'.freeze

  # Parsing the twelve schemas takes long enough to notice once per example.
  def self.schema
    # The document URL is what resolves the relative imports to the sibling files.
    @schema ||= Nokogiri::XML::Schema.from_document(Nokogiri::XML(OLAC_SCHEMA_PATH.read, OLAC_SCHEMA_PATH.to_s))
  end

  # The record arrives wrapped in an OAI-PMH envelope, and no OAI-PMH schema is vendored, so the
  # olac element is lifted out and validated on its own.
  def olac_records(body)
    Nokogiri::XML(body).xpath('//olac:olac', olac: OLAC_NAMESPACE).map { |record| Nokogiri::XML(record.to_xml) }
  end

  def olac_schema_errors(body)
    records = olac_records(body)
    raise 'no olac record in the response' if records.empty?

    records.flat_map { |record| OlacSchemaHelpers.schema.validate(record).map(&:message) }
  end
end
