require 'spec_helper'
require 'json_schemer'

RSpec.shared_examples_for "identifiable by doi" do |parent|
  let(:model) { described_class } # the class that includes the concern
  let(:schema) { JSONSchemer.schema(File.read('spec/support/schema/datacite_4.3_schema.json')) }
  let(:doi) { nil }
  let(:instance) { build(model.to_s.underscore.to_sym, doi: doi) }
  let(:json) { instance.to_doi_json('TEST') }

  describe '#to_doi_json' do
    it 'should conform to the metadata schema' do
      object = JSON.parse(instance.to_doi_json('TEST'))['data']['attributes']

      expect(object).to include({ 'event' => 'publish' })
      expect(object).to include({ 'prefix' => 'TEST' })

      object.delete 'event'
      object.delete 'prefix'
      object.delete 'url'

      errors = schema.validate(object).to_a

      errors.each do |err|
        puts "JSON Schemea Error: #{err['error']}"
      end

      # but hopefully there aren't any
      expect(errors.count).to eq(0)
    end

    it 'should include the originating university as a reference' do
      next if instance.is_a?(Essence)
      expect(json).to include(instance.university_name)
    end

    it 'should include the parent collection as a reference' do
      next unless parent
      expect(json).to include(instance.send(parent.to_sym).doi)
    end
  end

  describe '#citation' do
    context 'DOI exists' do
      let(:doi) { 'something' }

      it 'uses DOI, not URI' do
        expect(instance).to receive(:doi) { doi }.twice
        instance.citation
      end

      it 'does not blow up' do
        instance.citation
      end
    end

    context 'DOI nil' do
      let(:doi) { nil }

      it 'uses URI' do
        expect(instance).to receive(:doi) { doi }.once
        expect(instance).to receive(:full_path) { '' }
        instance.citation
      end

      it 'does not blow up' do
        instance.citation
      end
    end
  end
end
