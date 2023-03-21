require 'oai'

class ItemProvider < ApplicationProvider
  repository_url 'http://catalog.paradisec.org.au/oai/item'
  sample_id 'AA1-001'

  # FIXME: Doesn't include collection.
  source_model OAI::Provider::ActiveRecordWrapper.new(
    ::Item.public_items.includes(:essences, :subject_languages, :content_languages, :countries, :access_condition, :collector, :data_categories, item_agents: [:user, :agent_role]),
    :limit => 100,
  )

  xml = ::Builder::XmlMarkup.new
  xml.tag! 'description' do
    xml.tag! 'olac-archive', 'xmlns' => 'http://www.language-archives.org/OLAC/1.1/olac-archive', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'type' => 'institutional', 'currentAsOf' => Time.now().strftime('%Y-%m-%d'), 'xsi:schemaLocation' => 'http://www.language-archives.org/OLAC/1.1/olac-archive http://www.language-archives.org/OLAC/1.1/olac-archive.xsd' do
      xml.tag! 'archiveURL', 'http://catalog.paradisec.org.au'
      xml.tag! 'participant', 'name' => 'Nick Thieberger', 'role' => 'Project Director',  'email' => 'thien@unimelb.edu.au'
      xml.tag! 'participant', 'name' => 'Linda Barwick',  'role' => 'Project Manager', 'email' => 'Linda.Barwick@arts.usyd.edu.au'
      xml.tag! 'institution', 'A consortium made up of the University of Melbourne, University of Sydney, and the Australian National University'
      xml.tag! 'institutionURL', 'http://paradisec.org.au'
      xml.tag! 'shortLocation', 'Melbourne, Sydney, Canberra, Australia'
      xml.tag! 'location', 'PARADISEC Sydney Unit: Sydney Conservatorium of Music, C41, The University of Sydney, +61 2 9351 1383 | PARADISEC Melbourne Unit: School of Languages and Linguistics, University of Melbourne, +61 2 8344 8952 | PARADISEC Canberra Unit: College of Asia and the Pacific, The Australian National University, +61 2 6125 6115'
      xml.tag! 'synopsis', 'PARADISEC (Pacific And Regional Archive for Digital Sources in Endangered Cultures) offers a facility for digital conservation and access for endangered ethnographic materials from the Pacific region, defined broadly to include Oceania and East and South east Asia. Not all of the items listed here are currently digitised. The non-digitised items are part of an assessment of the scope of work that needs to be digitised. They also make otherwise inaccessible material discoverable.'
      xml.tag! 'access', 'The current focus of PARADISEC is securing endangered materials. Access to the datastore is by password and is currently only available to depositors via the following URL: http://catalog.paradisec.org.au/collections/[CollectionID]/items/[ItemID]. Page images of some fieldnotes can be located online.'
    end
  end

  extra_description xml.target!

  class << self
    def formats
      @filtered_formats ||= @formats.slice('oai_dc', 'olac')
    end
  end
end
