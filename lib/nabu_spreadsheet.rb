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
      coll_id = sheet1.row(3)[1]
      @collection = Collection.find_by_identifier coll_id
      collector = user_from_str(sheet1.row(6)[1], false)
      if !@collection
        if collector
          @collection = Collection.new
          @collection.identifier = coll_id
          @collection.title = sheet1.row(4)[1]
          @collection.description = sheet1.row(5)[1]
          @collection.collector = collection
          @collection.private = true
          if @collection.save
            @notices << "Created collection #{coll_id}, #{collection.title}, #{collection.description}"
          else
            @errors << "ERROR creating collection #{coll_id}, #{collection.title}, #{collection.description}"
            return
          end
        else
          @errors << "ERROR creating collection #{coll_id}, #{collection.title}, #{collection.description}"
          return
        end
      end

      # parse items in XSL file
      sheet1.each 12 do |row|
        break if row[0].nil? # if first cell empty

        coll_id, item_id = row[0].split('-')

        item = Item.find_by_identifier(item_id)
        if item
          @notices << "WARNING: item #{row[0]} already exists - skipped"
          next
        end

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

        # title and description
        if row[1].blank?
          item.title = "Please supply a title"
        else
          item.title = row[1]
        end
        if row[2].blank?
          item.description = "Please supply a description"
        else
          item.description = row[2]
        end

        # content and subject language
        content_language = Language.find_by_name(row[3])
        if content_language
          item.content_languages << content_language
        end
        subject_language = Language.find_by_name(row[4])
        if subject_language
          item.subject_languages << subject_language
        end

        # countries
        countries = row[5].split('|')
        countries.each do |country|
          code, _ = country.strip.split(' - ')
          cntry = Country.find_by_code(code.strip)
          next if !cntry
          item.countries << cntry
        end

        # origination date
        item.originated_on = row[6].to_date unless row[6].blank?

        if item.valid?
          @items << item
          @notices << "Item #{item.identifier} added"
        else
          @notices << "WARNING: item #{item.identifier} invalid - skipped, #{item.errors.inspect}"
        end
      end

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
