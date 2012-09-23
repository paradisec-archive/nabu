namespace :import do

  @verbose = false

  desc 'Setup database from old PARADISEC data & other imports'
  task :all => [:setup, :import, :clean]

  desc 'Setup database from old PARADISEC'
  task :setup => [:quiet, :dev_users, :add_identifiers, :access_cond_setup, :load_db]

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
                   :countries, :languages, :fields_of_research, :data_categories,
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
    system "sed -e 's/ TYPE=MyISAM//;' #{Rails.root}/db/legacy/paradisecDump.sql | mysql -u root paradisec_legacy"
  end


  ## ADD / REMOVE ID COLUMS

  class AddIdentifiers < ActiveRecord::Migration
    def change
      add_column :users, :pd_user_id, :integer
      add_column :users, :pd_contact_id, :integer

      add_column :items, :pd_coll_id, :string
      add_column :discourse_types, :pd_dt_id, :integer
      add_column :agent_roles, :pd_role_id, :integer
      add_column :data_categories, :pd_cat_id, :integer
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
    DataCategory.reset_column_information
  end

  desc 'Remove paradisec_legacy identifier colums to DBs for import tasks'
  task :remove_identifiers => :environment do
    puts "Removing identifiers from DB finalising import of PARADISEC legacy DB"
    AddIdentifiers.migrate(:down)
  end

  ## SETUP access_cond table and mapping function

  desc 'Create limited list of access conditions'
  task :access_cond_setup => :environment do
    AccessCondition.create! :name => "Open (subject to agreeing to PDSC access form)"
    AccessCondition.create! :name => "Open (subject to the access condition details)"
    AccessCondition.create! :name => "Closed (subject to the access condition details)"
    AccessCondition.create! :name => "Mixed (check individual items)"
    AccessCondition.create! :name => "As yet unspecified"
  end

  def getAccessCond(curr_cond)
    narrative = ""

    case curr_cond
    when "normal",
         "standard, as per PDSC Access form",
         "Tekee Media Ros Dunlop, Max Stahl",
         "Tekee Media Ros Dunlop",
         "Open (subject to agreeing to access conditions)"
      ac = AccessCondition.find_by_name "Open (subject to agreeing to PDSC access form)"

    when "non-profit"
      ac = AccessCondition.find_by_name "Open (subject to agreeing to PDSC access form)"
      narrative = curr_cond

    when "Open (subject to the following conditions)"
      ac = AccessCondition.find_by_name "Open (subject to the access condition details)"

    when "Access by permission of the depositor, except where speakers of Kagate wish to access the data, in which case permission can be granted by either the depositor or Norpu Kagate"
      ac = AccessCondition.find_by_name "Open (subject to the access condition details)"
      narrative = curr_cond

    when "Closed (subject to the following conditions)"
      ac = AccessCondition.find_by_name "Closed (subject to the access condition details)"

    when "restricted, no access except with depositor's permission",
         "Restricted, only acccessed by members of the families involved or by bona fide researchers with the permission of those members",
         "access restricted to depositor and Kokota community",
         "access restricted to depositor and Simbo community",
         "Recorded under the request of the widow Helen Ufrafo.  The content is not to be further reproduced and/ or commented publicly.",
         "Restricted; access available through Jadran Mimica only. Contains culturally sensitive materials.",
         "Not for wider distribution"
      ac = AccessCondition.find_by_name "Closed (subject to the access condition details)"
      narrative = curr_cond

    when "", nil
      ac = AccessCondition.find_by_name "As yet unspecified"

    else
      puts "ERROR: don't know what to do with access condition #{curr_cond} - marking closed"
      ac = AccessCondition.find_by_name "Closed (subject to the access condition details)"
      narrative = curr_cond

    end
    [ac, narrative]
  end

  ## Open DB connection

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
      $stderr.puts msg + " replacing with " + default
    else
      raise msg
    end
    default
  end

  desc 'Add some users for the development environment'
  task :dev_users => :environment do
    unless Rails.env.production?
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
      password = 'asdfgj'

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
    rights_transferred = []
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
        password = 'asdfgh'
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

        # remember users that have their rights transferred
        if user['cont_address1'] =~ /REPRESENTATIVE=(\d+)(?:,REASON=(\w+))/
          rights_transferred << {
            :user   => new_user,
            :rep    => $1,
            :reason => $2
          }
        end
      end
    end

    # fix up users with transferred rights
    rights_transferred.each do |right|
      rep_user = User.where(:pd_contact_id => right[:rep].to_i).first
      right[:user].rights_transferred_to_id = rep_user.id
      right[:user].rights_transfer_reason = right[:reason]
      right[:user].address = right[:user].address2
      right[:user].address2 = nil
      right[:user].save!
    end
  end


  ## FOR COLLECTIONS
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
    puts "Importing languages from ethnologue DB (with geocodes from legacy)"
    require 'iconv'

    # TODO Replace me with new data when we get it
    geo_codes = Hash.new
    client = connect
    ethnologues = client.query('SELECT * FROM ethnologue16')
    ethnologues.each do |e|
      geo_codes[e['eth_code']] = {
        :north_limit => e['eth_ymax'],
        :south_limit => e['eth_ymin'],
        :west_limit  => e['eth_xmin'],
        :east_limit  => e['eth_xmax'],
      }
    end

    data = File.open("#{Rails.root}/data/LanguageIndex.tab", "rb").read
    data = Iconv.iconv('UTF8', 'ISO-8859-1', data).first.force_encoding('UTF-8')
    # add three special language codes
    data += "mul\tMULTIPLE\tL\tMultiple languages\r\n"
    data += "und\tUNDETERMINED\tL\tUndetermined language\r\n"
    data += "zxx\tZXX\tL\tNo linguistic content\r\n"
    data.each_line do |line|
      next if line =~ /^LangID/
      code, country_code, name_type, name = line.strip.split("\t")
      next unless name_type == "L"

      # save language if new
      language = Language.find_by_code_and_name(code, name)
      if !language
        params = { :code => code, :name => name }
        params.merge!(geo_codes[code]) if (geo_codes[code])
        language = Language.new params
        if !language.valid?
          puts "Skipping adding language #{code}, #{name} errors: #{language.errors}" if @verbose
          next
        end
        language.save!
        puts "Saved language #{code} - #{name}" if @verbose
      end

      # save language - country mapping except for special language codes
      next if country_code == 'MULTIPLE' || country_code == 'UNDETERMINED' || country_code == 'ZXX'
      country = Country.find_by_code(country_code)
      if !country
        puts "Error: Country not in countries list #{country_code} - skipping"
        next
      end
      lang_country = CountriesLanguage.new :country => country, :language => language
      begin
        lang_country.save!
      rescue
        puts "Error saving county - language mapping lang=#{language.code} country=#{country.code}"
      end
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
        field.errors.each {|f, msg| puts "#{f}: #{msg}"}
        if Rails.env == "development"
          next
        end
      end
      field.save!
      puts "Saved field of research #{id}, #{name}" if @verbose
    end
  end

  desc 'Import data_categories into NABU from paradisec_legacy DB'
  task :data_categories => :environment do
    puts "Importing data categories from paradisec_legacy DB"
    client = connect
    categories = client.query("SELECT * FROM types")
    categories.each do |cat|
      category = DataCategory.new :name => cat['type_name']

      ## save PARADISEC identifier
      category.pd_cat_id = cat['type_id']
      if !category.valid?
        puts "Error adding category #{name}"
        category.errors.each {|field, msg| puts "#{field}: #{msg}"}
        if Rails.env == "development"
          next
        end
      end
      category.save!
      puts "Saved category #{name}" if @verbose
    end
  end

  desc 'Import collections into NABU from paradisec_legacy DB'
  task :collections => :environment do
    puts "Importing collections from PARADISEC legacy DB"
    client = connect
    collections = client.query("SELECT * FROM collections")
    collections.each do |coll|
      if coll['coll_id'].blank? or coll['coll_description']=="DELETE THIS COLLECTION"
        puts "Skipping collection with blank ID or marked for deletion"
        next
      end

      ## get collector & operator
      if !coll['coll_collector_id'] or coll['coll_collector_id'] == 0
        puts "ERROR: #{coll['coll_id']} has no collector (#{coll['coll_collector_id']}) - can't add to collections"
        next
      end
      collector = User.find_by_pd_contact_id coll['coll_collector_id']
      if !collector
        puts "ERROR: #{coll['coll_id']} has no collector (#{coll['coll_collector_id']}) - can't add to collections"
        next
      end
      operator = User.find_by_pd_contact_id coll['coll_operator_id']

      ## get university
      university = University.find_by_name coll['coll_original_uni']

      ## get access conditions
      access_cond, narrative = getAccessCond(coll['coll_access_conditions'])
      access_narrative = coll['coll_access_narrative']
      if !narrative.blank?
        if access_narrative.blank?
          access_narrative = narrative
        else
          access_narrative += '; ' + narrative
        end
      end

      ## make sure title and description aren't blank
      title = coll['coll_description']
      title = fixme(coll, 'coll_description', 'PLEASE PROVIDE TITLE') if title.blank?
      description = coll['coll_note']
      description = fixme(coll, 'coll_note', 'PLEASE PROVIDE DESCRIPTION') if description.blank?

      ## prepare record
      new_coll = Collection.new :identifier => coll['coll_id'],
                                :title => title,
                                :description => description,
                                :region => coll['coll_region_village'],
                                :access_narrative => access_narrative,
                                :metadata_source => coll['coll_metadata_source'],
                                :orthographic_notes => coll['coll_orthographic_notes'],
                                :media => coll['coll_media'],
                                :comments => coll['coll_comments'],
                                :deposit_form_received => coll['coll_depform_rcvd'],
                                :tape_location => coll['coll_location'],
                                :field_of_research_id => 1,
                                :north_limit => coll['coll_ymax'],
                                :south_limit => coll['coll_ymin'],
                                :west_limit  => coll['coll_xmin'],
                                :east_limit  => coll['coll_xmax']

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
    client = connect
    require 'csv'
    CSV.foreach("#{Rails.root}/db/legacy/collections.csv", :col_sep => "\t", :headers => true) do |row|
      collection = Collection.find_by_identifier row['coll_id']
      if collection
#        collection.title = row['coll_description'] unless row['coll_description'].blank?
#        collection.description = row['coll_note']  unless row['coll_note'].blank?
#        collection.comments = row['coll_comments'] if collection.comments.blank?
        field = FieldOfResearch.find_by_identifier(row['FOR'][/\d+/])
        if field
          collection.field_of_research = field
        end
        collection.save!
        puts "Updated collection #{row['coll_id']} #{row['coll_description']}, #{row['coll_note']}, #{row['coll_comments']}" if @verbose
      end
    end
  end

  desc 'Import collection_languages into NABU from paradisec_legacy DB'
  task :collection_languages => :environment do
    puts "Importing collection languages per collection from PARADISEC legacy DB"
    client = connect
    languages = client.query("SELECT * FROM collection_language16")
    languages.each do |lang|
      next if lang['cl_eth_code'].blank? || lang['cl_coll_id'].blank?
      language = Language.find_by_code(lang['cl_eth_code'])
      if !language
        lang_name = client.query("SELECT eth_name FROM ethnologue16 where eth_code='"+lang['cl_eth_code']+"'")
        language = Language.new :code => lang['cl_eth_code'], :name => lang_name.first['eth_name']+" (retired)", :retired => true
        begin
          language.save!
        rescue
          puts "Error: language code #{lang['cl_eth_code']} not found for collection #{lang['cl_coll_id']} - skipping collection language add"
        end
      end
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
      ## a few items can safely be skipped
      next if ["??1-ASS1", "??4-ASS", "ABW02-001", "Awtest-001",
               "Awtest-002", "Awtest-003", "Awtest-004", "Awtest-005",
               "JB2-001", "TEST-test", "aol_ak_061219-elic", "CJP1-001",
               "CK1-001", "EO1-001", "FD1-001", "PL1-arawa" ].include?(item['item_pid'])
      ## get collection
      if item['item_collection_id'].blank?
        puts "Skipping item #{item['item_pid']} #{item['item_id']} #{item['item_note']}"
        puts "item_collection_id is blank"
        next
      end
      collection = Collection.find_by_identifier item['item_collection_id']
      if !collection
        puts "Skipping item #{item['item_pid']} #{item['item_id']} #{item['item_note']}"
        puts "collection not found"
        next
      end

      ## get identifier (item_pid has full string, item_id may be truncated)
      first_dash = item['item_pid'].index('-')
      identifier = item['item_pid'][first_dash+1..-1]

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
      title = 'PLEASE PROVIDE TITLE' if title.blank?
      description = item['item_note']
      description = item['item_description'] if description.blank?

      ## origination date
      originated_on = nil
      originated_on_narrative = nil
      if item['item_date_iso'].blank?
        begin
          if item['item_date'] == "date unknown" || item['item_date'] == "unknown"
            originated_on = nil
          else
            originated_on = item['item_date'].to_date unless item['item_date'].blank?
          end
        rescue
          puts "Error importing item_date #{item['item_date']} for item #{item['item_pid']}"
          originated_on_narrative = item['item_date'] unless item['item_date'].blank?
        end
      else
        if item['item_date_iso'] == "1999-11-30"
          originated_on = nil
        else
          begin
            originated_on = item['item_date_iso'].to_date
          rescue
            puts "Error importing item_date_iso #{item['item_date_iso']} for item #{item['item_pid']}"
          end
        end
        if !item['item_date'].blank?
          begin
            if item['item_date_iso'].to_date != item['item_date'].to_date
              originated_on_narrative = item['item_date']
            end
          rescue
            ## save us if item[item_date] can't be converted to a date
            originated_on_narrative = item['item_date']
          end
        end
      end

      ## get access conditions
      access_cond, narrative = getAccessCond(item['item_rights'])

      ## get discourse type
      if !item['item_discourse_type'].blank?
        discourse_type = DiscourseType.find_by_pd_dt_id(item['item_discourse_type'])
      end

      ## set "owned" boolean
      item_owned = true
      if !item['item_url'].blank? && item['item_url'] !~ /paradisec/
        item_owned = false
      end

      ## prepare record
      new_item = Item.new :identifier => identifier,
                          :title => title,
                          :description => description,
                          :region => item['item_region_village'],
                          :language => item['item_source_language'],
                          :dialect => item['item_dialect'],
                          :url => item['item_url'],
                          :owned => item_owned,
                          :admin_comment => item['item_comments'],
                          :originated_on => originated_on,
                          :originated_on_narrative => originated_on_narrative,
                          :metadata_exportable => item['item_impxml_ready'],
                          :born_digital => item['item_born_digital'],
                          :tapes_returned => item['item_tapes_returned'],
                          :original_media => item['item_media'],
                          :ingest_notes => item['item_audio_notes'],
                          :tracking => item['item_tracking'],
                          :access_narrative => narrative,
                          :north_limit => item['item_ymax'],
                          :south_limit => item['item_ymin'],
                          :west_limit  => item['item_xmin'],
                          :east_limit  => item['item_xmax']

      ## set collection, collector, operator and university
      new_item.collection = collection
      new_item.collector = collector
      new_item.operator = operator
      new_item.university = university
      new_item.discourse_type = discourse_type

      ## set access_cond and private field from collection
      if access_cond
        new_item.access_condition_id = access_cond.id
      end
      new_item.private = false
      if item['item_hide_metadata'] == 1
          new_item.private = true
      end

      ## set dates
      if item['item_date_received'] != nil
        begin
          new_item.received_on = item['item_date_received'].to_date
        rescue
          puts "Error importing item_date_received #{item['item_date_received']} for item #{item['item_pid']}"
        end
      end
      if item['item_date_digitised'] != nil
        begin
          new_item.digitised_on = item['item_date_digitised'].to_date
        rescue
          puts "Error importing item_date_digitised #{item['item_date_digitised']} for item #{item['item_pid']}"
        end
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
        p new_item
        next
      end
      new_item.save!

      ## save data categories for item
      save_data_categories_for(client, new_item, item['item_pid'])

      ## fix created_at (updated_at is now)
      if item['item_date_created'] != nil
        begin
          ## weird import problem
          if item['item_pid'] == 'MD5-PH00401'
            new_item.created_at = "21-08-2007".to_date
          else
            new_item.created_at = item['item_date_created'].to_date
          end
          new_item.save!
        rescue
          puts "Error importing item_date_created #{item['item_date_created']} for item #{item['item_pid']}"
        end
      end
      puts "Saved item #{item['item_pid']} #{item['item_description']}, #{collector.id} #{collector.first_name} #{collector.last_name}" if @verbose
    end
  end

  def get_item(item_pid)
    first_dash = item_pid.index('-')
    coll_id = item_pid[0..first_dash-1]
    identifier = item_pid[first_dash+1..-1]
    collection = Collection.find_by_identifier coll_id
    return nil if !collection

    item = collection.items.find_by_identifier identifier
    item
  end

  def save_data_categories_for(client, item, item_pid)
    categories = client.query("SELECT * FROM item_type WHERE it_item_pid = '#{item_pid}'")
    categories.each do |cat|
      category = DataCategory.find_by_pd_cat_id(cat['it_type_id'])
      begin
        item_cat = ItemDataCategory.create! :item => item, :data_category => category
      rescue ActiveRecord::RecordNotUnique
      end
      puts "Saved category #{name} for item #{item_pid}" if @verbose
    end
  end

  desc 'Import item_content_languages into NABU from paradisec_legacy DB'
  task :item_content_languages => :environment do
    puts "Importing content languages per item from PARADISEC legacy DB"
    client = connect
    languages = client.query("SELECT * FROM item_language16")
    languages.each do |lang|
      next if lang['il_eth_code'].blank? || lang['il_item_pid'].blank?
      language = Language.find_by_code(lang['il_eth_code'])
      if !language
        lang_name = client.query("SELECT eth_name FROM ethnologue16 where eth_code='"+lang['il_eth_code']+"'")
        language = Language.new :code => lang['il_eth_code'], :name => lang_name.first['eth_name']+" (retired)", :retired => true
        begin
          language.save!
        rescue
          puts "Error: language code #{lang['il_eth_code']} not found for item #{lang['il_item_pid']} - skipping content language add"
        end
      end
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
    puts "Importing subject languages per item from PARADISEC legacy DB"
    client = connect
    languages = client.query("SELECT * FROM item_subjectlang16")
    languages.each do |lang|
      next if lang['is_eth_code'].blank? || lang['is_item_pid'].blank?
      language = Language.find_by_code(lang['is_eth_code'])
      if !language
        lang_name = client.query("SELECT eth_name FROM ethnologue16 where eth_code='"+lang['is_eth_code']+"'")
        language = Language.new :code => lang['is_eth_code'], :name => lang_name.first['eth_name']+" (retired)", :retired => true
        begin
          language.save!
        rescue
          puts "Error: language code #{lang['is_eth_code']} not found for item #{lang['is_item_pid']} - skipping subject language add"
        end
      end
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

      ## skip certain users
      next if agent['ir_role_content'] == "Evans, Nicholas Prof"
      next if agent['ir_role_content'] == "Roesler, Ruth H."
      next if agent['ir_role_content'] == "Voorhoeve, C.L."
      next if agent['ir_role_content'] == "Wurm, S.A."

      ## get or create a user
      results = agent['ir_role_content'].split(', ')
      if results.length > 2
        print "Invalid agent: "
        p agent
        next
      end
      last_name, first_name = agent['ir_role_content'].split(', ', 2)
      last_name.strip! unless last_name.nil?
      first_name.strip! unless first_name.nil?
      if first_name.blank?
        first_name, space, last_name = agent['ir_role_content'].rpartition(' ')
        last_name.strip! unless last_name.nil?
        first_name.strip! unless first_name.nil?
      end
      if first_name.blank?
        user = User.find_by_first_name last_name
      else
        user = User.find_by_first_name_and_last_name(first_name, last_name)
      end
      if user.nil?
        ## let's create a new user without email
        password = 'asdfgj'
        if first_name.blank?
          first_name = last_name
          last_name = ''
        end
        new_user = User.create!({:first_name => first_name,
                                :last_name => last_name,
                                :contact_only => true,
                                :password => password,
                                :password_confirmation => password}, :as => :admin)
        user = new_user
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
      mimetype.sub!(/^(wav|mp3|eaf)$/, 'audio/\1')
      mimetype.sub!(/^(jpg|tif|img)$/, 'image/\1')
      mimetype.sub!(/^(mov|mpg|mp4|dv)$/, 'video/\1')
      mimetype.sub!(/^(pdf|mxf|gpk|lex|lng|typ|cha)$/, 'application/\1')
      mimetype.sub!(/^(rtf|xml|trs)$/, 'text/\1')
      mimetype.sub!(/^(txt)$/, 'text/plain')
      mimetype.sub!(/^(001)$/, 'audio/eaf')

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

  desc 'Update essence meta_data'
  task :update_essences => :environment do
    puts 'Updating Essence metadata'
    Essence.find_each do |essence|
      media = Nabu::Media.new essence.path
      essence.mimetype = media.mimetype
      essence.size = media.size
      essence.bitrate = media.bitrate
      essence.samplerate = media.samplerate
      essence.duration = media.duration
      essence.channels = media.channels
      essence.fps = media.fps
      essence.save!
    end
  end
end
