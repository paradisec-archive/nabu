require 'spreadsheet'

module Nabu
  class NabuSpreadsheet
    attr_accessor :notices, :errors, :collection, :items

    def initialize
      @notices = []
      @errors = []
      @items = []
    end

    def parse(data, current_user)
      # open Spreadsheet as "file"
      s = StringIO.new data
      book = Spreadsheet.open s
      sheet1 = book.worksheet 0

      # parse collection in XSL file
      coll_id = sheet1.row(3)[1].to_s
      @collection = Collection.find_by_identifier coll_id
      collector = user_from_str(sheet1.row(6)[1], false)
      if !collector
        @errors << "ERROR collector does not exist"
        return
      end
      if !@collection
        @collection = Collection.new
        @collection.identifier = coll_id
        @collection.collector = collector
        @collection.private = true
        @collection.title = 'PLEASE PROVIDE TITLE'
        @collection.description = 'PLEASE PROVIDE DESCRIPTION'
        # update collection details
        @collection.title = sheet1.row(4)[1] unless sheet1.row(4)[1].blank?
        @collection.description = sheet1.row(5)[1] unless sheet1.row(5)[1].blank?
      else
        if @collection.collector != collector
          @errors << "Collection #{coll_id} exists but with different collector #{collector.name} - please fix spreadsheet"
          return
        end
      end
      if @collection.save
        @notices << "Saved collection #{coll_id}, #{collection.title}"
      else
        @errors << "ERROR saving collection #{coll_id}, #{collection.title}, #{collection.description}"
        return
      end

      # parse items in XSL file
      existing_items = ""
      sheet1.each 12 do |row|
        break if row[0].nil? # if first cell empty

        item_id = row[0].to_s

        # if collection_id is part of item_id string, remove it
        item_id.slice! "#{@collection.identifier}-"

        item = Item.where(:collection_id => @collection.id).where(:identifier => item_id)[0]
        if !item
          item = Item.new
          item.identifier = item_id
          item.collection = @collection
          item.private = true
          item.collector = collector

          # inherit from collection
          item.university_id = @collection.university_id
          item.operator_id = @collection.operator_id
          item.region = @collection.region
          item.north_limit = @collection.north_limit
          item.south_limit = @collection.south_limit
          item.west_limit = @collection.west_limit
          item.east_limit = @collection.east_limit
          item.access_condition_id = @collection.access_condition_id
          item.access_narrative = @collection.access_narrative
          item.admin_ids = @collection.admin_ids
          item.title = 'PLEASE PROVIDE TITLE'
          item.description = 'PLEASE PROVIDE DESCRIPTION'
        end

        # update title and description
        item.title = row[1].to_s unless row[1].blank?
        item.description = row[2].to_s unless row[2].blank?

        # add content and subject language
        if !row[3].blank?
          content_languages = row[3].split('|')
          content_languages.each do |language|
            content_language = Language.find_by_name(language)
            if content_language
              item.content_languages << content_language unless item.content_languages.include? content_language
            else
              @notices << "Item #{item.identifier} : Content language '#{language}' not found"
            end
          end
        end
        if !row[4].blank?
          subject_languages = row[4].split('|')
          subject_languages.each do |language|
            subject_language = Language.find_by_name(language)
            if subject_language
              item.subject_languages << subject_language unless item.subject_languages.include? subject_language
            else
              @notices << "Item #{item.identifier} : Subject language '#{language}' not found"
            end
          end
        end

        # add countries
        countries = row[5].split('|')
        countries.each do |country|
          code, _ = country.strip.split(' - ')
          cntry = Country.find_by_code(code.strip)
          if !cntry
            # try country name
            cntry = Country.find_by_name(code.strip)
            if !cntry
              @notices << "Item #{item.identifier} : Country not found - Item skipped"
              next
            end
          end
          item.countries << cntry unless item.countries.include? cntry
        end

        # add origination date
        if !row[6].to_s.empty?
          date = row[6].to_s
          if date.length == 4 ## take a guess they forgot the month & day
            date = date + "-01-01"
          end
          begin
            date_conv = date.to_date
          rescue
            @notices << "Item #{item.identifier} : Date invalid - Item skipped"
            next
          end
          item.originated_on = date_conv unless date_conv.blank?
        end

        if item.valid?
          @items << item
        else
          @notices << "WARNING: item #{item.identifier} invalid - skipped"
        end
      end

      @notices << "Existing items: #{existing_items.chomp(', ')}"

    end #parse

    def valid?
      @errors.empty? && @collection.valid?
    end

    private

    def user_from_str(name, create)
      if !name
        @errors << "Got no name for collector"
        return nil
      end

      first_name, last_name = name.split(',').map(&:strip)

      if last_name.nil?
        last_name = ''
      end

      user = User.first(:conditions => ["first_name = ? AND last_name = ?", first_name, last_name])

      if !user
        if !create
          @errors << "Please create user #{name} first<br/>"
          return nil
        end
        random_string = SecureRandom.base64(16)
        user = User.new()
        user.first_name = first_name
        user.last_name = last_name
        user.password = random_string
        user.password_confirmation = random_string
        user.contact_only = true
        if not user.valid?
          @errors << "Couldn't create user #{name}<br/>"
          return nil
        end
        @notices << "Note: Contact #{name} created<br/>"
      end
      user.save if user.valid?
      user
    end

  end

end
