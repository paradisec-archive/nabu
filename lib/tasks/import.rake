namespace :import do

  desc 'Setup database from old PARADISEC data & other imports'
  task :all => [:setup, :import]

  desc 'Setup database from old PARADISEC'
  task :setup => [:dev_users, :add_identifiers, :load_db]

  desc 'Import data from old PARADISEC DB & other files'
  task :import => [:users, :contacts,
                   :universities,
                   :countries, :languages, :fields_of_research,
                   :collections,
                   :collection_languages, :collection_countries, :collection_admins,
                   :discourse_types, :agent_roles,
                   :items]

  desc 'Teardown intermediate stuff'
  task :teardown => [:remove_identifiers]


##  HELPER ROUTINES ##

  ## FOR DB IMPORT

  desc 'Load database from old PARADISEC system'
  task :load_db do
    puts "Creating MySQL DB from old PARADISEC system"
    system 'echo "DROP DATABASE IF EXISTS paradisec_legacy" | mysql -u root'
    system 'echo "CREATE DATABASE paradisec_legacy" | mysql -u root'
    tables = %w{collection_language collection_language15 ethnologue ethnologue15 ethnologue16 ethnologue_country ethnologue_country15 ethnologue_country16 item_language item_language item_subjectlang item_subjectlang15}
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
      email = user['usr_email']
      if email.blank?
        email = fixme(user, 'usr_email', user['usr_id'].to_s+'@example.com')
      end

      ## password
      password = fixme(user, 'password', 'asdfgj')

      ## create user
      new_user = User.new :first_name => first_name,
                          :last_name => last_name,
                          :email => email,
                          :password => password,
                          :password_confirmation => password

      ## save PARADISEC identifier
      new_user.pd_user_id = user['usr_id']

      new_user.admin = access
      if !new_user.valid?
        puts "Error parsing User #{user['usr_id']}"
        puts "#{new_user.errors}"
        if Rails.env == "development"
          next
        end
      end
      new_user.save!
      puts "saved new user #{first_name} #{last_name}, #{email}, #{user['usr_id']}"
    end
  end

  desc 'Import contacts into NABU from paradisec_legacy DB (do users first)'
  task :contacts => :environment do
    puts "Importing contacts from PARADISEC legcacy DB"
    client = connect
    users = client.query("SELECT * FROM contacts")
    users.each do |user|
      next if user['cont_collector'].blank? && user['cont_collector_surname'].blank?
      last_name, first_name = user['cont_collector'].split(/, /, 2)
      if first_name.blank?
        first_name, last_name = user['cont_collector'].split(/ /, 2)
      end
      if last_name.blank?
        first_name = user['cont_collector']
        last_name = user['cont_collector_surname']
      end
      if user['cont_email']
        email = user['cont_email'].split(/ /)[0]
      end
      if email.blank?
        email = fixme(user, 'cont_email', user['cont_id'].to_s + 'cont@example.com')
      end
      address = user['cont_address1']
      if user['cont_address1'] && user['cont_address2']
        address = user['cont_address1'] + ',' + user['cont_address2']
      end

      # identify if this user already exists in DB
      cur_user = User.first(:conditions => ["first_name = ? AND last_name = ?", first_name, last_name])
      if cur_user
        cur_user.email = email
        cur_user.address = address
        cur_user.country = user['cont_country']
        cur_user.phone = user['cont_phone']
        cur_user.pd_contact_id = user['cont_id']
        cur_user.save!
        puts "saved existing user " + cur_user.email
      else
        password = fixme(user, 'password', 'asdfgh')
        new_user = User.new :first_name => first_name,
                            :last_name => last_name,
                            :email => email,
                            :password => password,
                            :password_confirmation => password,
                            :address => address,
                            :country => user['cont_country'],
                            :phone => user['cont_phone']

        ## save PARADISEC identifier
        new_user.pd_contact_id = user['cont_id']
        new_user.admin = false
        if !new_user.valid?
          puts "Error parsing contact #{user['cont_id']}"
          puts first_name + " " + last_name
        end
        new_user.save!
        puts "saved new user #{first_name} #{last_name}, #{email}, #{user['cont_id']}"
      end
    end
  end


  ## FOR COLLECTIONS

  def convert_coords(xmax, xmin, ymax, ymin)
    if (xmax && xmin && ymax && ymin)
      longitude = (xmax + xmin) / 2.0
      latitude = (ymax + ymin) / 2.0
      zoom = 20 - ((xmax - xmin) / 18)
      zoom =  zoom < 0 ? 0 : (zoom > 20 ? 20 : zoom)
    elsif (xmax == 0 && xmin == 0 && ymax == 0 && ymin == 0 )
      latitude = 0
      longitude = 0
      zoom = 1
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
      next if uni['uni_description'].empty?
      new_uni = University.new :name => uni['uni_description']
      if !new_uni.valid?
        puts "Error adding university #{uni['uni_description']}"
        if Rails.env == "development"
          next
        end
      end
      new_uni.save!
      puts "Saved university #{uni['uni_description']}"
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
        if Rails.env == "development"
          next
        end
      end
      country.save!
      puts "Saved country #{code} - #{name}"
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
      language = Language.new :code => code, :name => name
      if !language.valid?
        puts "Skipping adding language #{code}, #{name}"
        next
      end
      language.save!
      puts "Saved language #{code} - #{name}"
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
        if Rails.env == "development"
          next
        end
      end
      field.save!
      puts "Saved field of research #{id}, #{name}"
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
          puts "Saved access condition #{coll['coll_access_conditions']}"
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

      ## set dates
      new_coll.created_at = coll['coll_date_created']
      new_coll.updated_at = coll['coll_date_modified']

      ## TODO: when all items in coll have impl_ready, set complete to true
      new_coll.complete = false

      ## save record
      if !new_coll.valid?
        puts "Error adding collection #{coll['coll_id']} #{coll['coll_note']}"
        puts "#{new_coll.errors}"
      end
      new_coll.save!
      puts "Saved collection #{coll['coll_id']} #{coll['coll_description']}, #{collector.id} #{collector.first_name} #{collector.last_name}"
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
      puts "Saved for collection #{collection.identifier}: #{language.code} - #{language.name}"
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
      puts "Saved for collection #{collection.identifier}: #{cntry.code} - #{cntry.name}"
    end
  end

  desc 'Import collection_user_pem into NABU from paradisec_legacy DB'
  task :collection_admins => :environment do
    puts "Importing authorized users for collections from PARADISEC legacy DB"
    client = connect
    users = client.query("SELECT * FROM collection_user_perm")
    users.each do |user|
      next if user['cu_coll_id'].blank? || user['cu_usr_id'].blank?
      usr = User.find_by_pd_user_id user['cu_usr_id']
      collection = Collection.find_by_identifier user['cu_coll_id']
      admin = CollectionAdmin.new :collection => collection, :user => usr
      if !admin.valid?
        puts "Error adding admin user #{user['cu_usr_id']} for collection #{user['cu_coll_id']}"
        next
      end
      begin
        admin.save!
      rescue ActiveRecord::RecordNotUnique
      end
      puts "Saved admin for collection #{collection.identifier}: #{usr.first_name} #{usr.last_name}"
    end
  end


  ## FOR ITEMS

  desc 'Import discourse_types into NABU from paradisec_legacy DB'
  task :discourse_types => :environment do
    puts "Importing discourse types from PARADISEC legacy DB"
    client = connect
    discourses = client.query("SELECT * FROM discourse_types")
    discourses.each do |discourse|
      disc_type = DiscourseType.new :name => discourse['dt_name']

      ## save PARADISEC identifier
      disc_type.pd_dt_id = discourse['dt_id']

      if !disc_type.valid?
        puts "Error adding discourse type #{discourse['dt_name']}"
        next
      end
      disc_type.save!
      puts "Saved discourse type #{discourse['dt_name']}"
    end
  end

  desc 'Import agent_roles into NABU from paradisec_legacy DB'
  task :agent_roles => :environment do
    puts "Importing agent roles from PARADISEC legacy DB"
    client = connect
    roles = client.query("SELECT * FROM roles")
    roles.each do |role|
      new_role = AgentRole.new :name => role['role_name']

      ## save PARADISEC identifier
      new_role.pd_role_id = role['role_id']

      if !new_role.valid?
        puts "Error adding agent role '#{role['role_name']}'"
        next
      end
      new_role.save!
      puts "Saved agent role #{role['role_name']}"
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
      if item['item_date_iso'] != 0
        originated_on = item['item_date_iso']
      end

      ## prepare record
      new_item = Item.new :identifier => identifier,
                          :collector => collector,
                          :operator => operator,
                          :university => university,
                          :title => title,
                          :description => description,
                          :region => item['item_region_village'],
                          :dialect => item['item_dialect'],
                          :latitude => latitude,
                          :longitude => longitude,
                          :zoom => zoom.to_i,
                          :url => item['item_url'],
                          :access_narrative => item['item_comments'],
                          :originated_on => originated_on

      ## set collection, collector, operator and university
      new_item.collection = collection
      new_item.collector = collector
      new_item.operator = operator
      new_item.university = university

      ## save record
      if !new_item.valid?
        puts "Error adding item #{item['item_pid']} #{item['item_id']} #{item['item_note']}"
        p item
        p new_item.errors
        break
      end
      new_item.save!
      puts "Saved item #{item['item_pid']} #{item['item_description']}, #{collector.id} #{collector.first_name} #{collector.last_name}"
    end

#      t.boolean  "private"
#      t.string   "language"
#      t.integer  "subject_language_id"
#      t.integer  "content_language_id"
#      t.integer  "discourse_type_id"
#      t.text     "citation"
#      t.integer  "access_condition_id"
#      t.text     "comments"
#      t.datetime "created_at"
#      t.datetime "updated_at"
#      t.string   "pd_coll_id"

#| item_comments              | text         | YES  |     | NULL    |       |
#| item_rights                | varchar(255) | YES  |     | NULL    |       |
#| item_audio_notes           | text         | YES  |     | NULL    |       |
#| item_source_language       | varchar(255) | YES  |     | NULL    |       |
#| item_dialect               | varchar(255) | YES  |     | NULL    |       |
#| item_region_village        | varchar(255) | YES  |     | NULL    |       |
#| item_date_created          | date         | YES  |     | NULL    |       |
#| item_date_modified         | date         | YES  |     | NULL    |       |
#| item_time_modified         | datetime     | YES  |     | NULL    |       |
#| item_new                   | tinyint(1)   | NO   |     | 0       |       |
#| item_cd_burnt              | tinyint(1)   | NO   |     | 0       |       |
#| item_cd_id                 | varchar(255) | YES  |     | NULL    |       |
#| item_digitised             | tinyint(1)   | NO   |     | 0       |       |
#| item_date_digitised        | date         | YES  |     | NULL    |       |
#| item_tape_received         | tinyint(1)   | NO   |     | 0       |       |
#| item_date_received         | date         | YES  |     | NULL    |       |
#| item_metadata_entered      | tinyint(1)   | NO   |     | 0       |       |
#| item_hide_metadata         | tinyint(1)   | NO   |     | 0       |       |
#| item_tracking              | varchar(255) | YES  |     | NULL    |       |
#| item_media                 | varchar(255) | YES  |     | NULL    |       |
#| item_id_assigned           | tinyint(1)   | NO   |     | 0       |       |
#| item_number_of_cassettes   | smallint(6)  | YES  |     | NULL    |       |
#| item_number_of_rtors       | smallint(6)  | YES  |     | NULL    |       |
#| item_number_of_videos      | smallint(6)  | YES  |     | NULL    |       |
#| item_length_cassette       | double       | YES  |     | NULL    |       |
#| item_length_rtor           | double       | YES  |     | NULL    |       |
#| item_length_video          | double       | YES  |     | NULL    |       |
#| item_total_length_cassette | double       | YES  |     | NULL    |       |
#| item_total_length_rtor     | double       | YES  |     | NULL    |       |
#| item_total_length_video    | double       | YES  |     | NULL    |       |
#| item_speed_rtor            | varchar(31)  | YES  |     | NULL    |       |
#| item_radius                | double       | YES  |     | NULL    |       |
#| item_countries             | varchar(255) | YES  |     | NULL    |       |
#| item_impxml_ready          | tinyint(1)   | NO   |     | 0       |       |
#| tmp_item_ymin              | double       | YES  |     | NULL    |       |
#| tmp_item_ymax              | double       | YES  |     | NULL    |       |
#| item_impxml_done           | tinyint(1)   | NO   |     | 0       |       |
#| tmp_item_xmin              | double       | YES  |     | NULL    |       |
#| tmp_item_xmax              | double       | YES  |     | NULL    |       |
#| item_born_digital          | tinyint(1)   | NO   |     | 0       |       |
#| item_tapes_returned        | tinyint(1)   | NO   |     | 0       |       |
#| item_discourse_type        | smallint(6)  | YES  |     | NULL    |       |
  end

# - import item_admins
# - import item_agents
# - import item_countries

# - import content essences
end
