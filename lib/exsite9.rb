require 'nokogiri'
module Nabu
  class ExSite9
    attr_accessor :notices, :errors, :collection

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
      begin
        parse(doc)
      rescue ParseError
      end
    end

    private

    def user_from_str(name, create)
      last_name, first_name = name.split(/, /, 2)
      if first_name.blank?
        first_name, last_name = name.split(/ /, 2)
      end
      user = User.first(:conditions => ["first_name = ? AND last_name = ?", first_name, last_name])
      if !user && create
        random_string = SecureRandom.base64(16)
        user = User.new()
        user.first_name = first_name
        user.last_name = last_name
        user.password = random_string
        user.password_confirmation = random_string
        user.contact_only = true
        if not user.valid?
          @errors += "Couldn't create user #{name}<br/>"
          return nil 
        end
        @notices += "Note: Contact #{name} created<br/>"
      end
      user.save if user.valid?
      user
    end

    def parse(doc)
      # get collection information =======
      project_info = doc.xpath('//project_info').first
      if !project_info
        @errors = "ERROR: Not an ExSite9 file."
        raise ParseError
      end

      # is it a collection?
      collectionType = project_info['collectionType']
      if collectionType != "Collection"
        @errors = "ERROR: ExSite9 file does not contains collection information (collectionType = #{collectionType})."
        raise ParseError
      end

      # collection identifier
      collectionId = project_info['identifier'].strip
      coll = Collection.find_by_identifier(collectionId)
      unless coll.nil?
        @errors = "ERROR: Not a new collection #{collectionId} - can't overwrite."
        raise ParseError
      end
      @collection.identifier = collectionId

      # set private flag for reviews
      @collection.private = true

      # set current user as the operator
      @collection.operator = current_user

      # collection title
      if project_info.xpath('projectName').first
        @collection.title = project_info.xpath('projectName').first.content
      end

      # description
      if project_info.xpath('description').first
        @collection.description = project_info.xpath('description').first.content
      end

      # collector
      if project_info.xpath('name').first
        coll_name = project_info.xpath('name').first.content
        @collection.collector = user_from_str(coll_name, false)
        if @collection.collector.nil?
          @errors = "ERROR: Collector #{coll_name} not found."
          raise ParseError
        end
      end

      # institution
      if project_info.xpath('institution').first
        coll_uni = project_info.xpath('institution').first.content.strip
        university = University.find_by_name(coll_uni)
        if university.nil?
          coll_uni = coll_uni.split(/University of /)[1]
          university = University.find_by_name(coll_uni)
        end
        if university.nil?
          @notices += "Note: institution '#{coll_uni}' ignored<br/>" unless coll_uni.blank?
        else
          @collection.university = university
        end
      end

      # access rights
      if project_info.xpath('accessRights').first
        coll_access = project_info.xpath('accessRights').first.content.strip
        access_cond = AccessCondition.find_by_name(coll_access)
        if access_cond.nil?
          @notices += "Note: accessRight '#{coll_access}' ignored<br/>" unless coll_access.blank?
        else
          @collection.access_condition = access_cond
        end
      end

      # access narrative
      if project_info.xpath('rightsStatement').first
        @collection.access_narrative = project_info.xpath('rightsStatement').first.content.strip
      end

      # field or research
      if project_info.xpath('fieldOfResearch').first
        coll_for = project_info.xpath('fieldOfResearch').first.content.strip
        field_of_research = FieldOfResearch.find_by_identifier(coll_for.split(/ - /))
        if field_of_research.nil?
          @notices += "Note: fieldOfResearch '#{coll_for}' ignored<br/>" unless coll_for.blank?
        else
          @collection.field_of_research = field_of_research
        end
      end

      # region or village
      if project_info.xpath('placeOrRegionName').first
        @collection.region = project_info.xpath('placeOrRegionName').first.content
      end

      # physicalLocation
      if project_info.xpath('physicalLocation').first
        @collection.tape_location = project_info.xpath('physicalLocation').first.content
      end

      # languages, separated by |
      if project_info.xpath('languages').first
        languages = project_info.xpath('languages').first.content.split('|')
        languages.each do |language|
          code, _ = language.strip.split(' - ')
          lang = Language.find_by_code(code.strip)
          next if !lang
          @collection.languages << lang
        end
      end

      # countries, separated by |
      if project_info.xpath('countries').first
        countries = project_info.xpath('countries').first.content.split('|')
        countries.each do |country|
          code, _ = country.strip.split(' - ')
          cntry = Country.find_by_code(code.strip)
          next if !cntry
          @collection.countries << cntry
        end
      end

      # fundingBody
      if project_info.xpath('fundingBody').first
        coll_body = project_info.xpath('fundingBody').first.content
        funding_body = FundingBody.where("name LIKE '%#{coll_body}%'").first
        if funding_body.nil?
          if !coll_body.blank?
            funding_body = FundingBody.create!({
                :name => coll_body
            })
            @notices += "CHECK: fundingBody '#{funding_body}' created<br/>"
          end
        else
          @collection.funding_body = funding_body
        end
      end

      # grant_identifier
      if project_info.xpath('grantID').first
        @collection.grant_identifier = project_info.xpath('grantID').first.content
      end

      # datesOfCapture
      if project_info.xpath('datesOfCapture').first
        datesOfCapture = project_info.xpath('datesOfCapture').first.content
        if datesOfCapture.empty?
          @collection.comments = ""
        else
          @collection.comments = "Capture date: " + datesOfCapture + "; "
        end
      end

      # relatedInformation
      if project_info.xpath('relatedInformation').first
        @collection.comments += project_info.xpath('relatedInformation').first.content
      end

      # get the items (groups)
      groups = project_info.xpath('//groups/group')
      groups.each do |group|
        item = @collection.items.build
        item.collector = @collection.collector
        item.university = @collection.university
        item.identifier = group['name']
        item.title = group.xpath('Title').first.content if group.xpath('Title').first
        item.description = group.xpath('Description').first.content if group.xpath('Description').first
        if group.xpath('Private').first && group.xpath('Private').first.content == "True"
          item.private = group.xpath('Private').first.content == true
        else
          item.private = false
        end
        item.originated_on = group.xpath('originationDate').first.content.to_date if group.xpath('originationDate').first
        item.originated_on_narrative = group.xpath('originationDateNarrative').first.content if group.xpath('originationDateNarrative').first

        # LanguageLocalName, RegionVillage
        item.language = group.xpath('LanguageLocalName').first.content if group.xpath('LanguageLocalName').first
        item.region = group.xpath('RegionVillage').first.content if group.xpath('RegionVillage').first

        # data_category
        if group.xpath('Linguistic_Data_Type').first
          dataCategory = group.xpath('Linguistic_Data_Type').first.content.downcase.strip
          data_category = DataCategory.find_by_name(dataCategory)
          if data_category.nil?
            @notices += "Note: Linguistic_Data_Type '#{dataCategory}' ignored<br/>" unless dataCategory.blank?
          else
            item.data_categories << data_category
          end
        end

        # agents
        agents = group.xpath('Agent')
        agents.each do |agent|
          item_agent = ItemAgent.new
          item_agent.item = item
          item_agent.user = user_from_str(agent.content, true)
          item_agent.agent_role = AgentRole.find_by_name(agent['Role'].strip)
          if item_agent.user.nil? || item_agent.agent_role.nil?
            @notices += "Note: Agent #{agent.content} (#{agent['Role']}) ignored<br/>" unless agent.content.blank?
            next
          end
          if item.item_agents.select{|ia| ia.user_id == item_agent.user_id && ia.agent_role_id == item_agent.agent_role_id}.size == 0
            item.item_agents << item_agent
          else
            @notices += "Note: Duplicate item agent #{agent} ignored<br/>"
          end
        end

        # discourse type
        if group.xpath('Discourse_Type').first
          discourseType = group.xpath('Discourse_Type').first.content.downcase.strip
          discourseType = case discourseType
            when "dialogue"
              "interactive_discourse"
            when "formulaic"
              "formulaic_discourse"
            when "ludic"
              "language_play"
            when "procedural"
              "procedural_discourse"
            when "unintelligible"
              "unintelligible_speech"
            else discourseType
          end
          discourse_type = DiscourseType.find_by_name(discourseType)
          if discourse_type.nil?
            @notices += "Note: Discourse_Type '#{discourseType}' ignored<br/>" unless discourseType.blank?
          else
            item.discourse_type = discourse_type
          end
        end

        # country (possibly repeated field)
        if group.xpath('Country').first
          countries = group.xpath('Country')
          countries.each do |country|
            code, _ = country.content.strip.split(' - ')
            cntry = Country.find_by_code(code.strip)
            next if !cntry
            item.countries << cntry
          end
        end

        # subject language (possibly repeated field)
        if group.xpath('LanguageSubjectISO639-3').first
          languages = group.xpath('LanguageSubjectISO639-3')
          languages.each do |lang|
            code, _ = lang.content.strip.split(' - ')
            language = Language.find_by_code(code.strip)
            next if !language
            item.subject_languages << language
          end
        end

        # content language (possibly repeated field)
        if group.xpath('LanguageContentISO639-3').first
          languages = group.xpath('LanguageContentISO639-3')
          languages.each do |lang|
            code, _ = lang.content.strip.split(' - ')
            language = Language.find_by_code(code.strip)
            next if !langauge
            item.content_languages << language
          end
        end

      end
    end
  end
end
