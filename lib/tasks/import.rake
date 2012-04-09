namespace :import do
  
  @verbose = true

  desc 'Setup database from old PARADISEC data & other imports'
  task :all => [:setup, :import, :clean]

  desc 'Setup database from old PARADISEC'
  task :setup => [:quiet, :dev_users, :add_identifiers, :load_db]

  task :quiet do
    if ENV['DEBUG'].nil?
      @verbose = false
    else
      @verbose = true
    end
  end

  desc 'Import data from old PARADISEC DB & other files'
  task :import => [# for users
                   :users, :contacts,
                   # for collections
                   :universities,
                   :countries, :languages, :fields_of_research,
                   :collections, :csv,
                   :collection_languages, :collection_countries, :collection_admins,
                   # for items
                   :discourse_types, :agent_roles,
                   :items,
                   :item_content_languages, :item_subject_languages,
                   :item_countries, :item_admins, :item_agents,
                   # for essence files
                   :essences]

  desc 'Teardown intermediate stuff'
  task :clean => [:remove_identifiers]


##  HELPER ROUTINES ##

  ## FOR DB IMPORT

  desc 'Load database from old PARADISEC system'
  task :load_db do
    puts "Creating MySQL DB from old PARADISEC system"
    system 'echo "DROP DATABASE IF EXISTS paradisec_legacy" | mysql -u root'
    system 'echo "CREATE DATABASE paradisec_legacy" | mysql -u root'
    tables = %w{Retired_Codes Update_Mappings collection_language collection_language15 ethnologue ethnologue15 ethnologue16 ethnologue_country ethnologue_country15 ethnologue_country16 item_language item_language15 item_subjectlang item_subjectlang15}
    sed = 's/ TYPE=MyISAM//;'
    tables.each do |table|
      sed << "/CREATE TABLE #{table} /,/Table structure for table/d;"
    end
    system "sed -e '#{sed}' #{Rails.root}/db/legacy/paradisecDump.sql | mysql -u root paradisec_legacy"
  end


  ## ADD / REMOVE ID COLUMS

  class AddIdentifiers < ActiveRecord::Migration
    def change
      add_column :users, :pd_user_id, :integer
      add_column :users, :pd_contact_id, :integer

      add_column :items, :pd_coll_id, :string
      add_column :discourse_types, :pd_dt_id, :integer
      add_column :agent_roles, :pd_role_id, :integer
    end
  end

  desc 'Add paradisec_legacy identifier colums to DBs for import tasks'
  task :add_identifiers => :environment do
    puts "Adding identifiers to DB for import of PARADISEC legacy DB"
    AddIdentifiers.migrate(:up)
    User.reset_column_information
    Item.reset_column_information
    DiscourseType.reset_column_information
    AgentRole.reset_column_information
  end

  desc 'Remove paradisec_legacy identifier colums to DBs for import tasks'
  task :remove_identifiers => :environment do
    puts "Removing identifiers from DB finalising import of PARADISEC legacy DB"
    AddIdentifiers.migrate(:down)
  end


  def connect
    require 'mysql2'
    client = Mysql2::Client.new(:host => "localhost", :username => "root")
    client.query("use paradisec_legacy")
    client.query("set names utf8")
    client
  end

  ## FOR USERS

  def fixme(object, field, default = 'FIXME')
    msg = "#{object} has invalid field #{field}"
    if Rails.env == "development"
#      $stderr.puts msg + " replacing with " + default
    else
      raise msg
    end
    default
  end

  desc 'Add some users for the development environment'
  task :dev_users => :environment do
    return if Rails.env.production?
    puts 'Adding development Users'
    u = User.create :email => 'user@example.com',
                    :first_name => 'User',
                    :last_name => 'Doe',
                    :password => 'password',
                    :password_confirmation => 'password'
    u.confirm!
    u = User.create :email => 'admin@example.com',
                    :first_name => 'Admin',
                    :last_name => 'Doe',
                    :password => 'password',
                    :password_confirmation => 'password'
    u.confirm!
    u.admin!
  end

  desc 'Import users into NABU from paradisec_legacy DB'
  task :users => :environment do
    puts "Importing users from PARADISEC legacy DB"
    client = connect
    users = client.query("SELECT * FROM users")
    users.each do |user|
      next if user['usr_deleted'] == 1

      ## user name
      first_name, last_name = user['usr_realname'].split(/ /, 2)
      if last_name.blank?
        first_name = user['usr_realname']
        last_name = 'unknown'
      end

      ## admin access
      access = user['usr_access'] == 'administrator' ? true : false

      ## email
      email = nil
      contact_only = true
      if !user['usr_email'].blank?
        email = user['usr_email'].strip
        contact_only = false
      end

      ## password
      password = fixme(user, 'password', 'asdfgj')

      ## create user
      new_user = User.new({:first_name => first_name,
                          :last_name => last_name,
                          :email => email,
                          :password => password,
                          :password_confirmation => password,
                          :contact_only => contact_only}, :as => :admin)

      ## save PARADISEC identifier
      new_user.pd_user_id = user['usr_id']

      new_user.admin = access
      if !new_user.valid?
        puts "Error parsing User #{user['usr_id']}"
        new_user.errors.each {|field, msg| puts "#{field}: #{msg}"}
        if Rails.env == "development"
          next
        end
      end
      new_user.save!
      puts "Saved new user #{first_name} #{last_name}, #{email}, #{contact_only}, #{user['usr_id']}" if @verbose
    end
  end

  desc 'Import contacts into NABU from paradisec_legacy DB (do users first)'
  task :contacts => :environment do
    puts "Importing contacts from PARADISEC legcacy DB"
    client = connect
    users = client.query("SELECT * FROM contacts")
    users.each do |user|
      next if user['cont_collector'].blank? && user['cont_collector_surname'].blank?
      next if user['cont_address1'] == 'DELETE THIS RECORD'
      last_name, first_name = user['cont_collector'].split(/, /, 2)
      if first_name.blank?
        first_name, last_name = user['cont_collector'].split(/ /, 2)
      end
      if last_name.blank?
        first_name = user['cont_collector']
        last_name = user['cont_collector_surname']
      end
      email = nil
      contact_only = true
      if !user['cont_email'].blank?
        email = user['cont_email'].strip.split(/ /)[0]
        contact_only = false
      end

      # identify if this user already exists in DB
      cur_user = User.first(:conditions => ["first_name = ? AND last_name = ?", first_name, last_name])
      if cur_user
        cur_user.email = email if email # overwrite only if we have an email
        cur_user.contact_only = false if email # overwrite only if we have an email
        cur_user.address = user['cont_address1']
        cur_user.address2 = user['cont_address2']
        cur_user.country = user['cont_country']
        cur_user.phone = user['cont_phone']
        cur_user.pd_contact_id = user['cont_id']
        begin
          cur_user.save!
        rescue => e
          puts "Error updating contact: #{user['cont_id']} : #{user['cont_collector']}, #{user['cont_address1']}, #{user['cont_address2']}, #{user['cont_country']}, #{user['cont_email']}, #{user['cont_phone']}"
          puts e.message
        end
        puts "Saved existing user " + cur_user.last_name + ", " + cur_user.first_name if @verbose
      else
        password = fixme(user, 'password', 'asdfgh')
        new_user = User.new({:first_name => first_name,
                            :last_name => last_name,
                            :email => email,
                            :contact_only => contact_only,
                            :password => password,
                            :password_confirmation => password,
                            :address => user['cont_address1'],
                            :address2 => user['cont_address2'],
                            :country => user['cont_country'],
                            :phone => user['cont_phone']}, :as => :admin)

        ## save PARADISEC identifier
        new_user.pd_contact_id = user['cont_id']
        new_user.admin = false
        if !new_user.valid?
          puts "Error parsing contact #{user['cont_id']}"
          new_user.errors.each {|field, msg| puts "#{field}: #{msg}"}
          if Rails.env == "development"
            if !new_user.errors[:email].empty? # duplicate email
              new_user.email = nil 
              new_user.contact_only = true
            end
          end
        end
        begin
          new_user.save!
        rescue => e
          puts "Error importing contact: #{user['cont_id']} : #{user['cont_collector']}, #{user['cont_address1']}, #{user['cont_address2']}, #{user['cont_country']}, #{user['cont_email']}, #{user['cont_phone']}"
          puts e.message
        end
        puts "Saved new user #{first_name} #{last_name}, #{email}, #{contact_only}, #{user['cont_id']}" if @verbose
      end
    end
  end


  ## FOR COLLECTIONS

  def convert_coords(xmax, xmin, ymax, ymin)
    if (xmax == 0 && xmin == 0 && ymax == 0 && ymin == 0 )
      longitude = 0
      latitude = 0
      zoom = 1
    elsif xmax==xmin || ymax==ymin
      longitude = xmin.to_i
      latitude = ymin.to_i
      zoom = 11 # see below
    elsif (xmax && xmin && ymax && ymin)
      longitude = (xmax + xmin) / 2.0
      latitude = (ymax + ymin) / 2.0
      # copied from:
      # http://stackoverflow.com/questions/5939983/how-does-this-google-maps-zoom-level-calculation-work
      mapdisplay = 200; # min of height and width of element which contains the map
      dist = (6371 * Math.acos(Math.sin(ymin / 57.2958) * Math.sin(ymax / 57.2958) + (Math.cos(ymin / 57.2958) * Math.cos(ymax / 57.2958) * Math.cos((xmax / 57.2958) - (xmin / 57.2958)))))
      zoom = (8 - Math.log(1.6446 * dist / Math.sqrt(2 * (mapdisplay * mapdisplay))) / Math.log(2)).floor
    else
      latitude = 0
      longitude = 0
      zoom = 1
    end
    return [latitude, longitude, zoom]
  end

  desc 'Import universities into NABU from paradisec_legacy DB'
  task :universities => :environment do
    puts "Importing universities from PARADISEC legacy DB"
    client = connect
    universities = client.query("SELECT * FROM universities")
    universities.each do |uni|
      next if uni['uni_description'].blank?
      new_uni = University.new :name => uni['uni_description']
      if !new_uni.valid?
        puts "Error adding university #{uni['uni_description']}"
        new_uni.errors.each {|field, msg| puts "#{field}: #{msg}"}
        if Rails.env == "development"
          next
        end
      end
      new_uni.save!
      puts "Saved university #{uni['uni_description']}" if @verbose
    end
  end

  desc 'Import countries into NABU from ethnologue DB'
  task :countries => :environment do
    puts "Importing countries from ethnologue DB"
    require 'iconv'
    data = File.open("#{Rails.root}/data/CountryCodes.tab", "rb").read
    data = Iconv.iconv('UTF8', 'ISO-8859-1', data).first.force_encoding('UTF-8')
    data.each_line do |line|
      next if line =~ /^CountryID/
      code, name, area = line.split("\t")
      country = Country.new :name => name, :code => code
      if !country.valid?
        puts "Error adding country #{code}, #{name}, #{area}"
        country.errors.each {|field, msg| puts "#{field}: #{msg}"}
        if Rails.env == "development"
          next
        end
      end
      country.save!
      puts "Saved country #{code} - #{name}" if @verbose
    end
  end

  desc 'Import languages into NABU from ethnologue DB'
  task :languages => :environment do
    puts "Importing languages from ethnologue DB"
    require 'iconv'
    data = File.open("#{Rails.root}/data/LanguageIndex.tab", "rb").read
    data = Iconv.iconv('UTF8', 'ISO-8859-1', data).first.force_encoding('UTF-8')
    data.each_line do |line|
      next if line =~ /^LangID/
      code, country_code, name_type, name = line.strip.split("\t")
      next unless name_type == "L"
      language = Language.new :code => code, :name => name, :country_id => Country.where(:code => country_code).first.id
      if !language.valid?
        puts "Skipping adding language #{code}, #{name} errors: #{language.errors}" if @verbose
        next
      end
      language.save!
      puts "Saved language #{code} - #{name}" if @verbose
    end
  end

  desc 'Import fields_of_research into NABU from ANDS DB'
  task :fields_of_research => :environment do
    puts "Importing fields of research from ANDS DB"
    require 'iconv'
    data = File.open("#{Rails.root}/data/ANZSRC.txt", "rb").read
    data = Iconv.iconv('UTF8', 'ISO-8859-1', data).first.force_encoding('UTF-8')
    data.each_line do |line|
      id, name = line.split(" ", 2)
      id.strip!
      name.strip!
      field = FieldOfResearch.new :identifier => id, :name => name
      if !field.valid?
        puts "Error adding field of research #{id}, #{name}"
        field.errors.each {|field, msg| puts "#{field}: #{msg}"}        
        if Rails.env == "development"
          next
        end
      end
      field.save!
      puts "Saved field of research #{id}, #{name}" if @verbose
    end
  end

  desc 'Import collections into NABU from paradisec_legacy DB'
  task :collections => :environment do
    puts "Importing collections from PARADISEC legacy DB"
    client = connect
    collections = client.query("SELECT * FROM collections")
    collections.each do |coll|
      next if coll['coll_id'].blank?

      ## get collector & operator
      next if !coll['coll_collector_id'] or coll['coll_collector_id'] == 0
      collector = User.find_by_pd_contact_id coll['coll_collector_id']
      if !collector
        if !Rails.env == "development"
          raise "ERROR: #{new_coll} has no collector - can't add to collections"
        end
        next
      end
      operator = User.find_by_pd_contact_id coll['coll_operator_id']

      ## get university
      university = University.find_by_name coll['coll_original_uni']

      ## get map coordinates
      latitude, longitude, zoom = convert_coords(coll['coll_xmax'], coll['coll_xmin'],
                                                 coll['coll_ymax'], coll['coll_ymin'])

      ## get access conditions
      if !coll['coll_access_conditions'].blank?
        access_cond = AccessCondition.find_by_name coll['coll_access_conditions']
        if !access_cond
          access_cond = AccessCondition.create! :name => coll['coll_access_conditions']
          puts "Saved access condition #{coll['coll_access_conditions']}" if @verbose
        end
      end

      ## make sure title and description aren't blank
      title = coll['coll_description']
      title = fixme(coll, 'coll_description', 'PLEASE PROVIDE TITLE') if title.blank?
      description = coll['coll_note']
      description = fixme(coll, 'coll_note', 'PLEASE PROVIDE DESCRIPTION')

      ## prepare record
      new_coll = Collection.new :identifier => coll['coll_id'],
                                :title => title,
                                :description => description,
                                :region => coll['coll_region_village'],
                                :latitude => latitude,
                                :longitude => longitude,
                                :zoom => zoom.to_i,
                                :access_narrative => coll['coll_access_narrative'],
                                :metadata_source => coll['coll_metadata_source'],
                                :orthographic_notes => coll['coll_orthographic_notes'],
                                :media => coll['coll_media'],
                                :comments => coll['coll_comments'],
                                :deposit_form_recieved => coll['coll_depform_rcvd'],
                                :tape_location => coll['coll_location'],
                                :field_of_research_id => 1

      ## set collector, operator and university
      new_coll.collector = collector
      new_coll.operator = operator
      new_coll.university = university

      ## set access rights and private field
      new_coll.private = false
      if access_cond
        new_coll.access_condition_id = access_cond.id
        if access_cond.name == "not to be listed publicly (temporary)"
          new_coll.private = true
        end
      end

      ## TODO: when all items in coll have impl_ready, set complete to true
      new_coll.complete = false

      ## save record
      if !new_coll.valid?
        puts "Error adding collection #{coll['coll_id']} #{coll['coll_note']}"
        new_coll.errors.each {|field, msg| puts "#{field}: #{msg}"}
      end
      new_coll.save!

      ## fix date (updated at is now)
      if coll['coll_date_created'] != nil
        new_coll.created_at = coll['coll_date_created'].to_date
        new_coll.save!
      end
      puts "Saved collection #{coll['coll_id']} #{coll['coll_description']}, #{collector.id} #{collector.first_name} #{collector.last_name}" if @verbose
    end
  end

  desc 'Import csv file into NABU from PARADISEC'
  task :csv => :environment do
    puts "Importing csv file from PARADISEC"
    require 'csv'
    CSV.foreach("#{Rails.root}/db/legacy/collectionsNEW.csv", :col_sep => "\t", :headers => true) do |row|
      orthographic_notes    = row[6]
      conditions_of_storage = row[7]
      location              = row[8]
      access_conditions     = row[9]
      access_narrative      = row[10]
      metadata_source       = row[11]
      region_village        = row[12]
      date_assessed         = row[13]
      date_created          = row[14]
      date_modified         = row[15]
      depform_rcvd          = row[16]
      digitised             = row[17]
      country               = row[18]
      language              = row[19]
      collection = Collection.find_by_identifier row['coll_id']
      if collection
        collection.title = row['coll_description'] unless row['coll_description'].blank?
        collection.description = row['coll_note']  unless row['coll_note'].blank?
        collection.comments = row['coll_comments'] if collection.comments.blank?
        collection.save!
        puts "Updated collection #{row['coll_id']} #{row['coll_description']}, #{row['coll_note']}, #{row['coll_comments']}" if @verbose
      end
    end
  end

  desc 'Import collection_languages into NABU from paradisec_legacy DB'
  task :collection_languages => :environment do
    puts "Importing languages per collection from PARADISEC legacy DB"
    client = connect
    languages = client.query("SELECT * FROM collection_language16")
    languages.each do |lang|
      next if lang['cl_eth_code'].blank? || lang['cl_coll_id'].blank?
      language = Language.find_by_code(lang['cl_eth_code'])
      collection = Collection.find_by_identifier lang['cl_coll_id']
      next unless collection && language
      CollectionLanguage.create! :collection => collection, :language => language
      puts "Saved for collection #{collection.identifier}: #{language.code} - #{language.name}" if @verbose
    end
  end

  desc 'Import collection_countries into NABU from paradisec_legacy DB'
  task :collection_countries => :environment do
    puts "Importing countries per collection from PARADISEC legacy DB"
    client = connect
    countries = client.query("SELECT * FROM collection_country")
    countries.each do |country|
      next if country['cc_countrycode'].blank? || country['cc_coll_id'].blank?
      cntry = Country.find_by_code country['cc_countrycode']
      collection = Collection.find_by_identifier country['cc_coll_id']
      next unless cntry && collection
      CollectionCountry.create! :collection => collection, :country => cntry
      puts "Saved for collection #{collection.identifier}: #{cntry.code} - #{cntry.name}" if @verbose
    end
  end

  desc 'Import collection_user_prem into NABU from paradisec_legacy DB'
  task :collection_admins => :environment do
    puts "Importing authorized users for collections from PARADISEC legacy DB"
    client = connect
    users = client.query("SELECT * FROM collection_user_perm")
    users.each do |user|
      next if user['cu_coll_id'].blank? || user['cu_usr_id'].blank?
      usr = User.find_by_pd_user_id user['cu_usr_id']
      collection = Collection.find_by_identifier user['cu_coll_id']
      next if collection.nil? || usr.nil?
      admin = CollectionAdmin.find_by_collection_id_and_user_id collection.id, usr.id
      next if admin
      admin = CollectionAdmin.new :collection => collection, :user => usr
      if !admin.valid?
        puts "Error adding admin user #{user['cu_usr_id']} for collection #{user['cu_coll_id']}"
        admin.errors.each {|field, msg| puts "#{field}: #{msg}"}
        next
      end
      begin
        admin.save!
      rescue ActiveRecord::RecordNotUnique
      end
      puts "Saved admin for collection #{collection.identifier}: #{usr.first_name} #{usr.last_name}" if @verbose
    end
  end


  ## FOR ITEMS

  desc 'Import discourse_types into NABU from paradisec_legacy DB'
  task :discourse_types => :environment do
    puts "Importing discourse types from PARADISEC legacy DB"
    client = connect
    discourses = client.query("SELECT * FROM discourse_types")
    discourses.each do |discourse|
      next if discourse['dt_name'].blank?
      disc_type = DiscourseType.new :name => discourse['dt_name']

      ## save PARADISEC identifier
      disc_type.pd_dt_id = discourse['dt_id']

      if !disc_type.valid?
        puts "Error adding discourse type #{discourse['dt_name']}"
        disc_type.errors.each {|field, msg| puts "#{field}: #{msg}"}
        next
      end
      disc_type.save!
      puts "Saved discourse type #{discourse['dt_name']}" if @verbose
    end
  end

  desc 'Import agent_roles into NABU from paradisec_legacy DB'
  task :agent_roles => :environment do
    puts "Importing agent roles from PARADISEC legacy DB"
    client = connect
    roles = client.query("SELECT * FROM roles")
    roles.each do |role|
      next if role['role_name'].blank?
      new_role = AgentRole.new :name => role['role_name']

      ## save PARADISEC identifier
      new_role.pd_role_id = role['role_id']

      if !new_role.valid?
        puts "Error adding agent role '#{role['role_name']}'"
        new_role.errors.each {|field, msg| puts "#{field}: #{msg}"}
        next
      end
      new_role.save!
      puts "Saved agent role #{role['role_name']}" if @verbose
    end
  end

  desc 'Import items into NABU from paradisec_legacy DB'
  task :items => :environment do
    puts "Importing items from PARADISEC legacy DB"
    client = connect
    items = client.query("SELECT * FROM items")
    items.each do |item|
      ## get collection
      next if item['item_collection_id'].blank?
      collection = Collection.find_by_identifier item['item_collection_id']
      next unless collection

      ## get identifier (item_pid has full string, item_id may be truncated)
      coll_id, identifier = item['item_pid'].split /-/

      ## get collector and operator
      collector = User.find_by_pd_contact_id item['item_collector_id']
      collector = collection.collector if !collector
      operator = User.find_by_pd_contact_id item['item_operator_id']
      operator = collection.operator if !operator

      # get university
      university = University.find_by_name item['item_original_uni']
      university = collection.university if !university

      ## make sure title and description aren't blank
      title = item['item_description']
      title = fixme(item, 'item_description', 'PLEASE PROVIDE TITLE') if title.blank?
      description = item['item_note']
      description = fixme(item, 'item_note', 'PLEASE PROVIDE DESCRIPTION') if description.blank?

      ## get map coordinates
      latitude, longitude, zoom = convert_coords(item['item_xmax'], item['item_xmin'],
                                                 item['item_ymax'], item['item_ymin'])

      ## origination date
      if item['item_date_iso'].blank?
        begin
          if item['item_date'] == "date unknown" || item['item_date'] == "unknown"
            originated_on = nil
          else
            originated_on = item['item_date'].to_date unless item['item_date'].blank?
          end
        rescue
          puts "Error importing item_date #{item['item_date']} for item #{item['item_pid']}"
        end
      else
        if item['item_date_iso'] == "1999-11-30"
          originated_on = nil
        else
          originated_on = item['item_date_iso'].to_date
        end
      end

      ## get access conditions
      if !item['item_rights'].blank?
        access_cond = AccessCondition.find_by_name item['item_rights']
        if !access_cond
          access_cond = AccessCondition.create! :name => item['item_rights']
          puts "Saved access condition #{item['item_rights']}" if @verbose
        end
      end

      ## get discourse type
      if !item['item_discourse_type'].blank?
        discourse_type = DiscourseType.find_by_pd_dt_id(item['item_discourse_type'])
      end

      ## prepare record
      new_item = Item.new :identifier => identifier,
                          :title => title,
                          :description => description,
                          :region => item['item_region_village'],
                          :language => item['item_source_language'],
                          :dialect => item['item_dialect'],
                          :latitude => latitude,
                          :longitude => longitude,
                          :zoom => zoom.to_i,
                          :url => item['item_url'],
                          :access_narrative => item['item_comments'],
                          :originated_on => originated_on,
                          :metadata_exportable => item['item_impxml_ready'],
                          :born_digital => item['item_born_digital'],
                          :tapes_returned => item['item_tapes_returned'],
                          :original_media => item['item_media'],
                          :ingest_notes => item['item_audio_notes'],
                          :tracking => item['item_tracking']

      ## set collection, collector, operator and university
      new_item.collection = collection
      new_item.collector = collector
      new_item.operator = operator
      new_item.university = university
      new_item.discourse_type = discourse_type

      ## set access rights and private field from collection
      if access_cond
        new_item.access_condition_id = access_cond.id
      end
      new_item.private = false
      if item['item_hide_metadata'] == 1
          new_item.private = true
      end

      ## set dates
      if item['item_date_received'] != nil
        new_item.received_on = item['item_date_received'].to_date
      end
      if item['item_date_digitised'] != nil
        new_item.digitised_on = item['item_date_digitised'].to_date
      end
      if item['item_metadata_entered'] == true
        metadata_imported_on = Date.today
      end
      if item['item_impxml_done'] == true
        metadata_exported_on = Date.today
      end

      ## save record
      if !new_item.valid?
        puts "Error adding item #{item['item_pid']} #{item['item_id']} #{item['item_note']}"
        new_item.errors.each {|field, msg| puts "#{field}: #{msg}"}
        break
      end
      new_item.save!

      ## fix created_at (updated_at is now)
      if item['item_date_created'] != nil
        new_item.created_at = item['item_date_created'].to_date
        new_item.save!
      end
      puts "Saved item #{item['item_pid']} #{item['item_description']}, #{collector.id} #{collector.first_name} #{collector.last_name}" if @verbose
    end
  end

  def get_item(item_pid)
    coll_id, identifier = item_pid.split /-/
    collection = Collection.find_by_identifier coll_id
    return nil if !collection

    item = collection.items.find_by_identifier identifier
    item
  end

  desc 'Import item_content_languages into NABU from paradisec_legacy DB'
  task :item_content_languages => :environment do
    puts "Importing languages per item from PARADISEC legacy DB"
    client = connect
    languages = client.query("SELECT * FROM item_language16")
    languages.each do |lang|
      next if lang['il_eth_code'].blank? || lang['il_item_pid'].blank?
      language = Language.find_by_code(lang['il_eth_code'])
      item = get_item(lang['il_item_pid'])
      next unless item && language
      begin
        ItemContentLanguage.create! :item => item, :language => language
      rescue ActiveRecord::RecordNotUnique
      end
      puts "Saved for item #{lang['il_item_pid']}: #{language.code} - #{language.name}" if @verbose
    end
  end

  desc 'Import item_subject_languages into NABU from paradisec_legacy DB'
  task :item_subject_languages => :environment do
    puts "Importing languages per item from PARADISEC legacy DB"
    client = connect
    languages = client.query("SELECT * FROM item_subjectlang16")
    languages.each do |lang|
      next if lang['is_eth_code'].blank? || lang['is_item_pid'].blank?
      language = Language.find_by_code(lang['is_eth_code'])
      item = get_item(lang['is_item_pid'])
      next unless item && language
      begin
        ItemSubjectLanguage.create! :item => item, :language => language
      rescue ActiveRecord::RecordNotUnique
      end
      puts "Saved for item #{lang['is_item_pid']}: #{language.code} - #{language.name}" if @verbose
    end
  end

  desc 'Import item_countries into NABU from paradisec_legacy DB'
  task :item_countries => :environment do
    puts "Importing countries per item from PARADISEC legacy DB"
    client = connect
    countries = client.query("SELECT * FROM item_country")
    countries.each do |country|
      next if country['ic_countrycode'].blank? || country['ic_item_pid'].blank?
      cntry = Country.find_by_code country['ic_countrycode']
      item = get_item(country['ic_item_pid'])
      next unless cntry && item
      begin
        ItemCountry.create! :item => item, :country => cntry
      rescue ActiveRecord::RecordNotUnique
      end
      puts "Saved for item #{country['ic_item_pid']}: #{cntry.code} - #{cntry.name}" if @verbose
    end
  end

  desc 'Import item_user_perm into NABU from paradisec_legacy DB'
  task :item_admins => :environment do
    puts "Importing authorized users for items from PARADISEC legacy DB"
    client = connect
    users = client.query("SELECT * FROM item_user_perm")
    users.each do |user|
      next if user['iu_item_pid'].blank? || user['iu_usr_id'].blank?
      usr = User.find_by_pd_user_id user['iu_usr_id']
      item = get_item(user['iu_item_pid'])
      next unless item && usr
      admin = ItemAdmin.new :item => item, :user => usr
      if !admin.valid?
        puts "Error adding admin user #{user['iu_usr_id']} for item #{user['iu_item_pid']}"
        admin.errors.each {|field, msg| puts "#{field}: #{msg}"}
        next
      end
      begin
        admin.save!
      rescue ActiveRecord::RecordNotUnique
      end
      puts "Saved admin for item #{user['iu_item_pid']}: #{usr.first_name} #{usr.last_name}" if @verbose
    end
  end

  desc 'Import item_roles into NABU from paradisec_legacy DB'
  task :item_agents => :environment do
    puts "Importing agents per item from PARADISEC legacy DB"
    client = connect
    agents = client.query("SELECT * FROM item_role")
    agents.each do |agent|
      next if agent['ir_role_content'] == "unknown" || agent['ir_role_content'].blank? || agent['ir_role_content'] == "test"
      item = get_item(agent['ir_item_pid'])
      agent_role = AgentRole.find_by_pd_role_id agent['ir_role_id']
      next unless agent_role && item

      ## get or create a user
      results = agent['ir_role_content'].split(', ')
      if results.length > 2
        print "Invalid agent: "
        p agent
        next
      end
      last_name, first_name = agent['ir_role_content'].split(', ', 2)
      if first_name.blank?
        first_name, space, last_name = agent['ir_role_content'].rpartition(' ')
      end
      if last_name.blank?
        user = User.find_by_first_name first_name
      else
        user = User.find_by_first_name_and_last_name(first_name, last_name)
      end
      if !user
        ## let's create a new user without email
        password = fixme(user, 'password', 'asdfgj')
        begin
          if first_name.blank?
            first_name = last_name
            last_name = ''
          end
          new_user = User.create!({:first_name => first_name.strip,
                                  :last_name => last_name.strip,
                                  :contact_only => true,
                                  :password => password,
                                  :password_confirmation => password}, :as => :admin)
          user = new_user
        end
        puts "Saved new user #{first_name} #{last_name}" if @verbose
      end
      begin
        ItemAgent.create! :item => item, :agent_role => agent_role, :user => user
      rescue ActiveRecord::RecordNotUnique
      end
      puts "Saved for item #{agent['ir_item_pid']}: #{agent['ir_role_content']} - #{agent_role.name}" if @verbose
    end
  end

  desc 'Import essences into NABU from paradisec_legacy DB'
  task :essences => :environment do
    puts "Importing essences from PARADISEC legacy DB"
    client = connect
    essences = client.query("SELECT * FROM files")
    essences.each do |essence|
      ## get item
      next if essence['file_pid'].blank?
      item = get_item(essence['file_pid'])
      next unless item

      mimetype = essence['file_type']
      next if mimetype =~ /~/
      mimetype.sub! /^(wav|mp3|eaf)$/, 'audio/\1'
      mimetype.sub! /^(jpg|tif|img)$/, 'image/\1'
      mimetype.sub! /^(mov|mpg|mp4|dv)$/, 'video/\1'
      mimetype.sub! /^(pdf|mxf|gpk|lex|lng|typ|cha)$/, 'application/\1'
      mimetype.sub! /^(rtf|xml|trs)$/, 'text/\1'
      mimetype.sub! /^(txt)$/, 'text/plain'
      mimetype.sub! /^(001)$/, 'audio/eaf'

      essence['file_bitrate'] = nil if essence['file_bitrate'] == 0
      essence['file_trackcount'] = nil if essence['file_trackcount'] == 0
      essence['file_samplerate'] = nil if essence['file_samplerate'] == 0
      if essence['file_time'].nil?
        seconds = nil
      elsif essence['file_time'] == '00:00:00.00'
        seconds = nil
      else
        rest, ms = essence['file_time'].split '.'
        hh, mm, ss = rest.split ':'
        seconds = hh.to_i*60*60 + mm.to_i*60 + ss.to_i + "0.#{ms}".to_f
      end
      ## prepare record
      new_essence = Essence.create! :item => item,
                                    :filename => essence['file_filename'],
                                    :mimetype => mimetype,
                                    :bitrate => essence['file_bitrate'],
                                    :samplerate => essence['file_samplerate'],
                                    :size => (rand 1_000_000_000),
                                    :duration => seconds,
                                    :channels => essence['file_trackcount']

      puts "Saved essence #{essence['file_filename']} for item #{essence['file_pid']}" if @verbose
    end
  end

end
