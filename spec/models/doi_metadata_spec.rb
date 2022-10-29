require 'spec_helper'
require 'nokogiri'

describe IdentifiableByDoi do
  let!(:xsd) { Nokogiri::XML::Schema.new(File.open('spec/support/schema/kernel-3.1/metadata.xsd')) }
  context 'with collection' do
    let!(:collection) {build(:collection)}

    describe '#to_doi_xml' do
      it 'should conform to the metadata schema' do
        doixml = collection.to_doi_xml
        doc = Nokogiri::XML::Document.parse(doixml)
        errors = xsd.validate(doc)

        #if there are any errors, print them out
        errors.each do |err|
          puts err.inspect
        end
        #but hopefully there aren't any
        expect(errors.count).to eq(0)
      end

      it 'should include the originating university as a reference' do
        doixml = collection.to_doi_xml
        expect(doixml).to include(collection.university_name)
      end
    end
  end
  context 'with item' do
    let!(:item) {build(:item)}

    describe '#to_doi_xml' do
      it 'should conform to the metadata schema' do
        doixml = item.to_doi_xml
        doc = Nokogiri::XML::Document.parse(doixml)
        errors = xsd.validate(doc)

        #if there are any errors, print them out
        errors.each do |err|
          puts err.inspect
        end
        #but hopefully there aren't any
        expect(errors.count).to eq(0)
      end

      it 'should include the parent collection as a reference' do
        doixml = item.to_doi_xml
        expect(doixml).to include(item.collection.doi)
      end

      it 'should include the originating university as a reference' do
        doixml = item.to_doi_xml
        expect(doixml).to include(item.university_name)
      end
    end
  end

  context 'with essence' do
    let!(:essence) {build(:sound_essence)}

    describe '#to_doi_xml' do
      it 'should conform to the metadata schema' do
        pending 'Fails on Codeship' if ENV['CI_NAME'] == 'codeship'
        doixml = essence.to_doi_xml
        doc = Nokogiri::XML::Document.parse(doixml)
        errors = xsd.validate(doc)

        #if there are any errors, print them out
        errors.each do |err|
          puts err.inspect
        end
        #but hopefully there aren't any
        expect(errors.count).to eq(0)
      end

      it 'should include the parent item as a reference' do
        doixml = essence.to_doi_xml
        expect(doixml).to include(essence.item.doi)
      end
    end
  end
end
