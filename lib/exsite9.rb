require 'nokogiri'
module Nabu
  class ExSite9
    def initialize(data)
      @errors = ""
      @notices = ""
      @collection = nil
      # parse XML file
      doc  = Nokogiri::XML data
      if doc.errors.count > 0
        @errors = "ERROR: Unable to parse XML file (#{doc.errors.join(',')})."
        raise ParseError
      end
      @collection = Collection.new
      parse(doc)
    end

    def errors
      @errors
    end

    def notices
      @notices
    end

    def collection
      @collection
    end

    private

    def user_from_str(name, create=false)
      last_name, first_name = name.split(/, /, 2)
      if first_name.blank?
        first_name, last_name = name.split(/ /, 2)
      end
      user = User.first(:conditions => ["first_name = ? AND last_name = ?", first_name, last_name])
      if !user && create
        random_string = SecureRandom.base64(16)
        user = User.create!({
                 :first_name => first_name,
                 :last_name => last_name,
                 :password => random_string,
                 :password_confirmation => random_string,
                 :contact_only => true}, :as => :contact_only)
        @notices += "Note: Contact #{name} created<br/>"
      end
      user
    end

    def parse(doc)
      # get collection information =======
      project_info = doc.xpath('//project_info')
      if !project_info[0]
        @errors = "ERROR: Not an ExSite9 file."
        raise ParseError
      end

      # is it a collection?
      collectionType = project_info[0]['collectionType']
      if collectionType != "Collection"
        @errors = "ERROR: ExSite9 file does not contains collection information (collectionType = #{collectionType})."
        raise ParseError
      end

      # collection identifier
      collectionId = project_info[0]['identifier']
      coll = Collection.find_by_identifier(collectionId)
      unless coll.nil?
        @errors = "ERROR: Not a new collection #{collectionId} - can't overwrite."
        raise ParseError
      end
      @collection.identifier = collectionId

      # collection title
      if project_info[0].xpath('//projectName').first
        @collection.title = project_info[0].xpath('//projectName').first.content
      end

      # description
      if project_info[0].xpath('//description').first
        @collection.description = project_info[0].xpath('//description').first.content
      end

      # collector
      if project_info[0].xpath('//name').first
        coll_name = project_info[0].xpath('//name').first.content
        @collection.collector = user_from_str(coll_name, false)
        if @collection.collector.nil?
          @errors = "ERROR: Collector #{coll_name} not found."
          raise ParseError
        end
      end

      # institution
      if project_info[0].xpath('//institution').first
        coll_uni = project_info[0].xpath('//institution').first.content
        university = University.find_by_name(coll_uni)
        if university.nil?
          coll_uni = coll.uni.split(/University of /)[1]
          university = University.find_by_name(coll_uni)
        end
        if university.nil?
          @notices += "Note: institution '#{coll_uni}' ignored<br/>" unless coll_uni.blank?
        else
          @collection.university = university
        end
      end

      # access rights
      if project_info[0].xpath('//accessRights').first
        coll_access = project_info[0].xpath('//accessRights').first.content
        access_cond = AccessCondition.find_by_name(coll_access)
        if access_cond.nil?
          @notices += "Note: accessRight '#{coll_access}' ignored<br/>" unless coll_access.blank?
        else
          @collection.access_condition = access_cond
        end
      end

      # access narrative
      if project_info[0].xpath('//rightsStatement').first
        @collection.access_narrative = project_info[0].xpath('//rightsStatement').first.content
      end

      # field or research
      if project_info[0].xpath('//fieldOfResearch').first
        coll_for = project_info[0].xpath('//fieldOfResearch').first.content
        field_of_research = FieldOfResearch.find_by_identifier(coll_for.split(/ - /))
        if field_of_research.nil?
          @notices += "Note: fieldOfResearch '#{coll_for}' ignored<br/>" unless coll_for.blank?
        else
          @collection.field_of_research = field_of_research
        end
      end

      # region or village
      if project_info[0].xpath('//placeOrRegionName').first
        @collection.region = project_info[0].xpath('//placeOrRegionName').first.content
      end

      # physicalLocation
      if project_info[0].xpath('//physicalLocation').first
        @collection.tape_location = project_info[0].xpath('//physicalLocation').first.content
      end

      # languages, separated by |
      if project_info[0].xpath('//languages').first
        languages = project_info[0].xpath('//languages').first.content.split('|')
        languages.each do |language|
          code, name = language.split(' - ')
          lang = Language.find_by_code(code)
          @collection.languages << lang
        end
      end

      # countries, separated by |
      if project_info[0].xpath('//countries').first
        countries = project_info[0].xpath('//countries').first.content.split('|')
        countries.each do |country|
          code, name = country.split(' - ')
          cntry = Country.find_by_code(code)
          @collection.countries << cntry
        end
      end

      # fundingBody
      if project_info[0].xpath('//fundingBody').first
        coll_body = project_info[0].xpath('//fundingBody').first.content
        funding_body = FundingBody.find_by_name(coll_body)
        if funding_body.nil?
          @notices += "Note: fundingBody '#{funding_body}' ignored<br/>" unless coll_body.blank?
        else
          @collection.funding_body = funding_body
        end
      end

      # grant_identifier
      if project_info[0].xpath('//grantID').first
        @collection.grant_identifier = project_info[0].xpath('//grantID').first.content
      end

      # relatedGrant
      if project_info[0].xpath('//relatedGrant').first
        relatedGrant = project_info[0].xpath('//relatedGrant').first.content
        if !@collection.grant_identifier
          @collection.grant_identifier = relatedGrant
        end
      end

      # datesOfCapture
      if project_info[0].xpath('//datesOfCapture').first
        datesOfCapture = project_info[0].xpath('//datesOfCapture').first.content
        if datesOfCapture.nil?
          @collection.comments = ""
        else
          @collection.comments = "Capture date: " + datesOfCapture + "; "
        end
      end

      # relatedInformation
      if project_info[0].xpath('//relatedInformation').first
        @collection.comments += project_info[0].xpath('//relatedInformation').first.content
      end

      # get the items (groups)
      groups = project_info[0].xpath('//group')
      groups.each do |group|
        item = @collection.items.build
        item.identifier = group['name']
        item.title = group.xpath('//Title').first.content if group.xpath('//Title').first
        item.description = group.xpath('//Description').first.content if group.xpath('//Description').first
        if group.xpath('//Private').first && group.xpath('//Private').first.content == "True"
          item.private = group.xpath('//Private').first.content == true
        else
          item.private = false
        end
        item.originated_on = group.xpath('//originationDate').first.content.to_date if group.xpath('//originationDate').first
        item.originated_on_narrative = group.xpath('//originationDateNarrative').first.content if group.xpath('//originationDateNarrative')

        # data_category
        if group.xpath('//Linguistic_Data_Type').first
          dataCategory = group.xpath('//Linguistic_Data_Type').first.content
          data_category = FundingBody.find_by_name(dataCategory)
          if data_category.nil?
            @notices += "Note: Linguistic_Data_Type '#{dataCategory}' ignored<br/>" unless dataCategory.blank?
          else
            item.data_category = data_category
          end
        end

        # agents
        agents = group.xpath('//Agent')
        agents.each do |agent|
          itemAgent = item.item_agents.build
          itemAgent.user = user_from_str(agent.content, true)
          itemAgent.agent_role = AgentRole.find_by_name(agent['Role'])
          if itemAgent.user.nil? || itemAgent.agent_role.nil?
            @notices += "Note: Agent #{agent.content} (#{agent['Role']}) ignored<br/>" unless agent.content.blank?
          end
p itemAgent
        end

  p item
      end
    end
  end
end
