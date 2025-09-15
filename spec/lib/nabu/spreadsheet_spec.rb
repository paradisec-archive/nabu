require 'rails_helper'

# This test suite generates some random strings as output, as a result of the `before_validation` block of `User`.
# It may be possible to eliminate it, but there's the risk of something going wrong as a result.
describe Nabu::Spreadsheet do
  let(:spreadsheet) { described_class.new_of_correct_type(data) }
  let(:data) { File.binread('spec/support/data/minimal_metadata/470 PDSC_minimal_metadataxls.xls') }

  before do
    User.destroy_all
    Essence.destroy_all
    Item.all.each { |item| ItemDestructionService.destroy(item) }
    Collection.destroy_all
    AgentRole.destroy_all
    DataCategory.destroy_all
    DataType.destroy_all
    DiscourseType.destroy_all
    Country.create!(code: 'AD', name: 'Andorra') unless Country.find_by_code('AD')
    Country.create!(code: 'AF', name: 'Afghanistan') unless Country.find_by_code('AF')
    Language.create!(code: 'eng', name: 'English') unless Language.find_by_code('eng')
    Language.create!(code: 'deu', name: 'German') unless Language.find_by_code('deu')
    Language.create!(code: 'cmn', name: 'Mandarin') unless Language.find_by_code('cmn')
    Language.create!(code: 'yue', name: 'Cantonese') unless Language.find_by_code('yue')
    DataCategory.create!(name: 'primary text') unless DataCategory.find_by_name('primary text')
    DataType.create!(name: 'MovingImage') unless DataType.find_by_name('MovingImage')
    DataType.create!(name: 'PhysicalObject') unless DataType.find_by_name('PhysicalObject')
    DiscourseType.create!(name: 'formulaic_discourse') unless DiscourseType.find_by_name('formulaic_discourse')
    create(:user, first_name: 'VKS', last_name: nil)
    # Don't create this user - see if the parser can create a contact only user instead.
    # create(:user, first_name: 'John', last_name: 'Smith')
    create(:user, first_name: 'Andrew', last_name: 'Grimm')
    create(:agent_role, name: 'speaker')
    create(:agent_role, name: 'recorder')
  end

  describe '#load_spreadsheet' do
    context 'xls file provided' do
      it 'is valid' do
        spreadsheet.parse
        expect(spreadsheet).to be_valid
      end

      it 'has no errors' do
        spreadsheet.parse
        expect(spreadsheet.errors).to eq([])
      end

      it 'has no warnings' do
        spreadsheet.parse
        expect(spreadsheet.notices - ["Saved collection VKS, Recording of Selako", "Note: Contact John Smith created<br/>"]).to eq([])
      end
    end

    context 'xlsx file provided', :skip => "fix this later" do
      let(:data) { File.binread('spec/support/data/minimal_metadata/470 PDSC_minimal_metadataxls.xlsx') }

      it 'is valid' do
        spreadsheet.parse
        expect(spreadsheet).to be_valid
      end

      it 'has no errors' do
        spreadsheet.parse
        expect(spreadsheet.errors).to eq([])
      end

      it 'has no warnings' do
        spreadsheet.parse
        expect(spreadsheet.notices - ["Saved collection VKS, Recording of Selako", "Note: Contact John Smith created<br/>"]).to eq([])
      end
    end

    context 'non-xls non-xlsx file provided' do
      let(:data) { 'Garbage content' }

      it 'is invalid' do
        spreadsheet.parse
        expect(spreadsheet).not_to be_valid
      end
    end
  end

  describe 'Past versions' do
    context 'Version 3' do
      let(:data) { File.binread('spec/support/data/minimal_metadata/Version 3 PDSC_minimal_metadataxls.xls') }

      it 'is valid' do
        spreadsheet.parse
        expect(spreadsheet).to be_valid
      end

      it 'has no errors' do
        spreadsheet.parse
        expect(spreadsheet.errors).to eq([])
      end

      it 'has no warnings' do
        spreadsheet.parse
        expect(spreadsheet.notices - ["Saved collection VKS, Recording of Selako", "Note: Contact John Smith created<br/>"]).to eq([])
      end

      it 'is parsed by Version3Spreadsheet' do
        expect(spreadsheet).to be_a(Nabu::Spreadsheet::Version3)
      end
    end
  end

  describe 'Formatting issues', :skip => "fix this later" do
    context 'Automatic format for identifier' do
      let(:data) { File.binread('spec/support/data/minimal_metadata/Paradisec minimal data numeric identifier 20160727a.xls') }

      it 'is valid' do
        spreadsheet.parse
        expect(spreadsheet).to be_valid
      end

      it 'has no errors' do
        spreadsheet.parse
        expect(spreadsheet.errors).to eq([])
      end

      it 'has no warnings' do
        spreadsheet.parse
        expect(spreadsheet.notices - ["Saved collection VKS, Recording of Selako", "Note: Contact John Smith created<br/>"]).to eq([])
      end

      it 'determines item identifier' do
        spreadsheet.parse
        item = spreadsheet.items.first
        expect(item.identifier).to eq('107')
      end
    end
  end

  describe '#parse' do
    it 'determines collection identifier' do
      spreadsheet.parse
      collection = spreadsheet.collection
      # Note: Collection ID and Collector is the same in test data spreadsheet.
      expect(collection.identifier).to eq('VKS')
    end

    it 'determines collection title' do
      spreadsheet.parse
      collection = spreadsheet.collection
      expect(collection.title).to eq('Recording of Selako')
    end

    it 'determines collection description' do
      spreadsheet.parse
      collection = spreadsheet.collection
      expect(collection.description).to eq('Tribal history recounted by elders')
    end

    it 'determines item identifier' do
      spreadsheet.parse
      item = spreadsheet.items.first
      expect(item.identifier).to eq('107_79')
    end

    it 'determines item title' do
      spreadsheet.parse
      item = spreadsheet.items.first
      # Difference from identifier is this uses a dash, not an underscore
      expect(item.title).to eq('107-79')
    end

    it 'determines item description' do
      spreadsheet.parse
      item = spreadsheet.items.first
      expect(item.description).to eq('Nius blong Santo ribelion we Jimi Stevens i tekem ova Santo taon long May 28th 1980, ')
    end

    it 'can handle non-ASCII characters' do
      spreadsheet.parse
      item = spreadsheet.items[1]
      expect(item.description).to eq('Burlo, Maë, ')
    end

    it 'can handle content language codes' do
      spreadsheet.parse
      item = spreadsheet.items.first
      content_language_codes = item.content_languages.map(&:code)
      expect(content_language_codes).to include('eng')
    end

    it 'can handle content language names' do
      spreadsheet.parse
      item = spreadsheet.items.first
      content_language_codes = item.content_languages.map(&:code)
      expect(content_language_codes).to include('deu')
    end

    it 'can handle subject language codes' do
      spreadsheet.parse
      item = spreadsheet.items.first
      subject_language_codes = item.subject_languages.map(&:code)
      expect(subject_language_codes).to include('cmn')
    end

    it 'can handle subject language names' do
      spreadsheet.parse
      item = spreadsheet.items.first
      subject_language_codes = item.subject_languages.map(&:code)
      expect(subject_language_codes).to include('yue')
    end

    it 'can handle countries' do
      spreadsheet.parse
      item = spreadsheet.items.first
      country_codes = item.countries.map(&:code)
      expect(country_codes).to eq(%w[AD AF])
    end

    it 'can handle origination date' do
      spreadsheet.parse
      item = spreadsheet.items.first
      expect(item.originated_on).to eq(Date.new(2015, 10, 26))
    end

    it 'can handle region' do
      spreadsheet.parse
      item = spreadsheet.items.first
      expect(item.region).to eq('Oceania, Indian Ocean, Polynesia')
    end

    it 'can handle original media' do
      spreadsheet.parse
      item = spreadsheet.items.first
      expect(item.original_media).to eq('Text')
    end

    # This only tests it can parse one data category, but code for multiple categories are implemented
    it 'can handle data categories' do
      spreadsheet.parse
      item = spreadsheet.items.first
      expect(item.data_categories.first.name).to eq('primary text')
    end

    it 'can handle data types' do
      spreadsheet.parse
      item = spreadsheet.items.first
      expect(item.data_types.map(&:name)).to eq(['MovingImage', 'PhysicalObject'])
    end

    it 'can handle discourse type' do
      spreadsheet.parse
      item = spreadsheet.items.first
      expect(item.discourse_type.name).to eq('formulaic_discourse')
    end

    it 'can handle dialect' do
      spreadsheet.parse
      item = spreadsheet.items.first
      expect(item.dialect).to eq('Viennese')
    end

    it 'can handle language as given' do
      spreadsheet.parse
      item = spreadsheet.items.first
      expect(item.language).to eq('German')
    end

    it "can handle first agent's role" do
      spreadsheet.parse
      item = spreadsheet.items.first
      item_agent = item.item_agents.first
      expect(item_agent.agent_role.name).to eq("speaker")
    end

    it "can create a contact-only user" do
      spreadsheet.parse
      item = spreadsheet.items.first
      item_agent = item.item_agents.first
      expect(item_agent.user.contact_only).to eq(true)
    end
  end
end
