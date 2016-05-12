module Nabu
  class NabuSpreadsheet
    attr_accessor :notices, :errors, :collection, :items

    def initialize
      @notices = []
      @errors = []
      @items = []
    end

    def parse(data, current_user)
      book = load_spreadsheet(data)
      return unless @errors.empty?

      book.sheet 0
      # parse collection in XSL file
      coll_id = book.row(4)[1].to_s
      @collection = Collection.find_by_identifier coll_id
      collector = user_from_str(book.row(7)[1], false)
      unless collector
        @errors << "ERROR collector does not exist"
        return
      end
      unless @collection
        @collection = Collection.new
        @collection.identifier = coll_id
        @collection.collector = collector
        @collection.private = true
        @collection.title = 'PLEASE PROVIDE TITLE'
        @collection.description = 'PLEASE PROVIDE DESCRIPTION'
        # update collection details
        @collection.title = book.row(5)[1] unless book.row(5)[1].blank?
        @collection.description = book.row(6)[1] unless book.row(6)[1].blank?
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

      # parse items in XLS file
      existing_items = ""
      13.upto(book.last_row) do |row_number|
        row = book.row(row_number)
        break if row[0].nil? # if first cell empty
        parse_row(row, collector)
      end

      @notices << "Existing items: #{existing_items.chomp(', ')}"

    end #parse

    def valid?
      @errors.empty? && @collection.valid?
    end

    private

    # In theory, the program could determine which extension to try first by using Content-Type.
    def load_spreadsheet(data)
      # open Spreadsheet as "file"
      string_io = StringIO.new(data)
      book = try_xls(string_io) || try_xlsx(string_io)
      @errors << 'ERROR File is neither XLS nor XLSX' unless book
      book
    end

    def try_xls(string_io)
      Roo::Spreadsheet.open(string_io, extension: :xls)
    rescue Ole::Storage::FormatError
      nil
    end

    def try_xlsx(string_io)
      Roo::Spreadsheet.open(string_io, extension: :xlsx)
    rescue Zip::Error
      nil
    end

    def user_from_str(name, create)
      unless name
        @errors << "Got no name for collector"
        return nil
      end

      first_name, last_name = name.split(',').map(&:strip)

      if last_name == ''
        last_name = nil
      end

      user = User.where(first_name: first_name, last_name: last_name).first

      unless user
        unless create
          @errors << "Please create user #{name} first<br/>"
          return nil
        end
        random_string = SecureRandom.base64(16)
        user = User.new(
          first_name: first_name,
          last_name: last_name,
          password: random_string,
          password_confirmation: random_string,
          contact_only: true
        )
        unless user.valid?
          @errors << "Couldn't create user #{name}<br/>"
          return nil
        end
        @notices << "Note: Contact #{name} created<br/>"
      end
      user.save if user.valid?
      user
    end

    def parse_row(row, collector)
      item_id = row[0].to_s

      # if collection_id is part of item_id string, remove it
      item_id.slice! "#{@collection.identifier}-"

      item = Item.where(:collection_id => @collection.id).where(:identifier => item_id)[0]
      unless item
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
      if row[3].present?
        content_languages = row[3].split('|')
        content_languages.each do |language|
          content_language = Language.find_by_name(language) || Language.find_by_code(language)
          if content_language
            item.content_languages << content_language unless item.content_languages.include? content_language
          else
            @notices << "Item #{item.identifier} : Content language '#{language}' not found"
          end
        end
      end
      if row[4].present?
        subject_languages = row[4].split('|')
        subject_languages.each do |language|
          subject_language = Language.find_by_name(language) || Language.find_by_code(language)
          if subject_language
            item.subject_languages << subject_language unless item.subject_languages.include? subject_language
          else
            @notices << "Item #{item.identifier} : Subject language '#{language}' not found"
          end
        end
      end

      # add countries
      if row[5].present?
        countries = row[5].split('|')
        countries.each do |country|
          code, _ = country.strip.split(' - ')
          cntry = Country.find_by_code(code.strip)
          unless cntry
            # try country name
            cntry = Country.find_by_name(code.strip)
            unless cntry
              @notices << "Item #{item.identifier} : Country not found - Item skipped"
              return nil
            end
          end
          item.countries << cntry unless item.countries.include? cntry
        end
      end

      # add origination date
      if row[6].present?
        date = row[6].to_s
        if date.length == 4 ## take a guess they forgot the month & day
          date = date + "-01-01"
        end
        begin
          date_conv = date.to_date
        rescue
          @notices << "Item #{item.identifier} : Date invalid - Item skipped"
          return
        end
        item.originated_on = date_conv unless date_conv.blank?
      end

      if item.valid?
        @items << item
      else
        @notices << "WARNING: item #{item.identifier} invalid - skipped"
      end
    end
  end

end
