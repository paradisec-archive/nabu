# == Schema Information
#
# Table name: items
#
#  id                      :integer          not null, primary key
#  collection_id           :integer          not null
#  identifier              :string(255)      not null
#  private                 :boolean
#  title                   :string(255)      not null
#  url                     :string(255)
#  collector_id            :integer          not null
#  university_id           :integer
#  operator_id             :integer
#  description             :text             default(""), not null
#  originated_on           :date
#  language                :string(255)
#  dialect                 :string(255)
#  region                  :string(255)
#  discourse_type_id       :integer
#  access_condition_id     :integer
#  access_narrative        :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  metadata_exportable     :boolean
#  born_digital            :boolean
#  tapes_returned          :boolean
#  original_media          :text
#  received_on             :datetime
#  digitised_on            :datetime
#  ingest_notes            :text
#  metadata_imported_on    :datetime
#  metadata_exported_on    :datetime
#  tracking                :text
#  admin_comment           :text
#  external                :boolean          default(FALSE)
#  originated_on_narrative :text
#  north_limit             :float
#  south_limit             :float
#  west_limit              :float
#  east_limit              :float
#  doi                     :string(255)
#

# FIXME: This includes this module within Object. That's bad.
include ActionView::Helpers::SanitizeHelper
class Item < ActiveRecord::Base
  include IdentifiableByDoi

  delegate :url_helpers, :to => 'Rails.application.routes'
  has_paper_trail
  nilify_blanks

  belongs_to :collection
  belongs_to :collector, :class_name => 'User'
  belongs_to :operator, :class_name => 'User'
  belongs_to :university
  belongs_to :access_condition
  belongs_to :discourse_type

  has_many :item_countries, :dependent => :destroy
  has_many :countries, :through => :item_countries, :validate => true

  has_many :item_subject_languages, :dependent => :destroy
  has_many :subject_languages, :through => :item_subject_languages, :source => :language, :validate => true

  has_many :item_content_languages, :dependent => :destroy
  has_many :content_languages, :through => :item_content_languages, :source => :language, :validate => true

  has_many :item_admins, :dependent => :destroy
  has_many :admins, :through => :item_admins, :validate => true, :source => :user

  has_many :item_users, :dependent => :destroy
  has_many :users, :through => :item_users, :validate => true, :source => :user

  has_many :item_agents, :dependent => :destroy
  has_many :agents, :through => :item_agents, :validate => true, :source => :user

  has_many :item_data_categories, :dependent => :destroy
  has_many :data_categories, :through => :item_data_categories, :validate => true

  has_many :essences, :dependent => :restrict
  has_many :comments, :as => :commentable, :dependent => :destroy

  # require presence of these three fields.
  validates :identifier, :presence => true,
            :uniqueness => {:scope => [:collection_id, :identifier]},
            :format => { :with => /^[a-zA-Z0-9_]*$/, :message => "error - only letters and numbers and '_' allowed" }
  validates_length_of :identifier, :within => 2..30
  validates :title, :presence => true
  validates :collector_id, :presence => true

  validates :north_limit, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}, :allow_nil => true
  validates :south_limit, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}, :allow_nil => true
  validates :west_limit, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}, :allow_nil => true
  validates :east_limit, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}, :allow_nil => true

  bulk = [
    :bulk_edit_append_title, :bulk_edit_append_description, :bulk_edit_append_region,
    :bulk_edit_append_originated_on_narrative, :bulk_edit_append_url, :bulk_edit_append_language,
    :bulk_edit_append_dialect, :bulk_edit_append_original_media, :bulk_edit_append_ingest_notes,
    :bulk_edit_append_tracking, :bulk_edit_append_access_narrative, :bulk_edit_append_admin_comments,
    :bulk_edit_append_country_ids, :bulk_edit_append_subject_language_ids, :bulk_edit_append_content_language_ids,
    :bulk_edit_append_admin_ids, :bulk_edit_append_user_ids, :bulk_edit_append_data_category_ids
  ]
  attr_reader(*bulk)
  attr_accessible :identifier, :title, :external, :url, :description, :region, :collection_id,
                  :north_limit, :south_limit, :west_limit, :east_limit,
                  :collector_id, :university_id, :operator_id,
                  :country_ids, :data_category_ids,
                  :content_language_ids, :subject_language_ids,
                  :admin_ids, :agent_ids, :user_ids, :item_agents_attributes,
                  :access_condition_id,
                  :access_narrative, :private,
                  :admin_comment,
                  :originated_on, :originated_on_narrative, :language,
                  :dialect, :discourse_type_id,
                  :metadata_exportable, :born_digital, :tapes_returned,
                  :original_media, :ingest_notes, :tracking,
                  *bulk,
                  :received_on, :digitised_on, :metadata_imported_on, :metadata_exported_on

  accepts_nested_attributes_for :item_agents, :allow_destroy => true, :reject_if => :all_blank

  delegate :name, :to => :collector, :prefix => true, :allow_nil => true
  delegate :sortname, :to => :collector, :prefix => true, :allow_nil => true
  delegate :name, :to => :operator, :prefix => true, :allow_nil => true
  delegate :name, :to => :university, :prefix => true, :allow_nil => true
  delegate :name, :to => :discourse_type, :prefix => true, :allow_nil => true
  delegate :name, :to => :access_condition, :prefix => true, :allow_nil => true

  DUPLICATABLE_ASSOCIATIONS = %w(countries subject_languages content_languages
                         admins users agents data_categories)


  paginates_per 10

  after_initialize :prefill

  after_save :update_collection_countries_and_languages

  scope :public, joins(:collection).where(:private => false, :collection => {:private => false})

  def has_default_map_boundaries?
    if (north_limit == 80.0) && (south_limit == -80.0) && (east_limit == -40.0) && (west_limit == -20.0)
      true
    else
      false
    end
  end

  def public?
    self.private == false && self.collection.private == false
  end

  def full_identifier
    collection.identifier + '-' + identifier
  end

  def full_path
    # FIX ME
    "http://catalog.paradisec.org.au/collections/#{collection.identifier}/items/#{identifier}"
  end

  # for DOI relationship linking: nil <- Collection <- Item <- Essence
  def parent
    collection
  end

  def path
    basepath = Nabu::Application.config.archive_directory + '/' + collection.identifier + '/' + identifier + '/'
    filename = "#{full_identifier}-CAT-PDSC_ADMIN.xml"
    basepath + filename
  end

  def xml_key
    "paradisec.org.au/item/#{full_identifier}"
  end

  def essence_types
    essences.map(&:type).uniq
  end

  def prefill
    return unless collection
    return unless new_record?

    self.university_id ||= collection.university_id
    self.collector_id ||= collection.collector_id
    self.operator_id ||= collection.operator_id

    self.region ||= collection.region
    self.north_limit ||= collection.north_limit
    self.south_limit ||= collection.south_limit
    self.west_limit ||= collection.west_limit
    self.east_limit ||= collection.east_limit
    self.country_ids = collection.country_ids
    self.subject_language_ids = collection.language_ids
    self.content_language_ids = collection.language_ids

    self.access_condition_id ||= collection.access_condition_id
    self.access_narrative ||= collection.access_narrative
    self.private ||= collection.private
    self.admin_ids = collection.admin_ids
  end

  def inherit_details_from_collection(override = false)
    return unless collection

    inherited_attributes = {
      subject_languages: collection.languages,
      content_languages: collection.languages,
      access_condition: collection.access_condition,
      operator: collection.operator,
      countries: collection.countries,
      north_limit: collection.north_limit,
      south_limit: collection.south_limit,
      east_limit: collection.east_limit,
      west_limit: collection.west_limit,
      access_narrative: collection.access_narrative,
      region: collection.region
    }

    unless override
      # by default, only inherit attributes which don't already have a value
      existing_attributes = Hash[*inherited_attributes.keys.map do |key|
                                   val = self.public_send(key)
                                   [key.to_sym, val] unless val.blank?
                                 end.reject{|x| x.nil?}.flatten(1)]
      # -> this merge causes the current attribute value to replace the inherited one before we update
      inherited_attributes = inherited_attributes.merge(existing_attributes)
    end
    # since the attributes here are already explicitly whitelisted, just inherit them and don't add to attr_accessible

    inherited_attributes.each_pair do |key, val|
      self.public_send("#{key}=", val)
    end
    self.save
  end

  def self.sortable_columns
    %w{full_identifier title collector_sortname updated_at language}
  end

  searchable do
    # Things we want to perform full text search on
    text :title
    text :identifier, :as => :identifier_textp
    text :full_identifier, :as => :full_identifier_textp
    text :collector_name
    text :university_name
    text :operator_name
    text :description
    text :language
    text :dialect
    text :region
    text :discourse_type_name
    text :access_narrative
    text :ingest_notes
    text :tracking
    text :original_media
    text :content_languages do
      content_languages.map(&:name)
    end
    text :subject_languages do
      subject_languages.map(&:name)
    end
    text :countries do
      countries.map(&:name)
    end
    text :data_categories do
      data_categories.map(&:name)
    end
    text :filename do
      essences.map(&:filename)
    end
    text :mimetype do
      essences.map(&:mimetype)
    end
    text :fps do
      essences.map(&:fps)
    end
    text :samplerate do
      essences.map(&:samplerate)
    end
    text :channels do
      essences.map(&:channels)
    end

    # Link models for faceting or dropdowns
    integer :content_language_ids, :references => Language, :multiple => true
    integer :collector_id, :references => User
    integer :operator_id, :references => User
    integer :country_ids, :references => Country, :multiple => true
    integer :university_id, :references => University
    integer :subject_language_ids, :references => Language, :multiple => true
    integer :data_category_ids, :references => DataCategory, :multiple => true
    integer :discourse_type_id, :references => DiscourseType
    integer :access_condition_id, :references => AccessCondition
    integer :agent_ids, :references => User, :multiple => true
    integer :admin_ids, :references => User, :multiple => true
    integer :user_ids, :references => User, :multiple => true

    # Things we want to sort or use :with on
    integer :id
    string :title
    string :identifier
    string :full_identifier
    string :university_name
    string :collector_name
    string :collector_sortname
    string :region
    string :language
    string :identifier
    string :collection_identifier do
      collection.identifier
    end
    boolean :private
    boolean :external
    date :originated_on
    float :north_limit
    float :south_limit
    float :west_limit
    float :east_limit
    boolean :metadata_exportable
    boolean :born_digital
    boolean :tapes_returned
    time :received_on
    time :digitised_on
    time :metadata_imported_on
    time :metadata_exported_on
    time :created_at
    time :updated_at
    string :content_languages, :multiple => true do
      content_languages.map(&:name)
    end
    string :subject_languages, :multiple => true do
      subject_languages.map(&:name)
    end
    string :countries, :multiple => true do
      countries.map(&:name)
    end
    string :data_categories, :multiple => true do
      data_categories.map(&:name)
    end
    string :filename, multiple: true do
      essences.map(&:filename)
    end
    string :mimetype, multiple: true do
      essences.map(&:mimetype)
    end

    # Things we want to check blankness of
    blank_fields = [:title, :description, :originated_on, :originated_on_narrative, :url, :language, :dialect, :region, :original_media, :received_on, :digitised_on, :ingest_notes, :metadata_imported_on, :metadata_exported_on, :tracking, :access_narrative, :admin_comment]
    blank_fields.each do |f|
      boolean "#{f}_blank".to_sym do
        self.public_send(f).blank?
      end
    end
  end

  def next_item
    Item.where(:collection_id => self.collection).order(:identifier).where('identifier > ?', self.identifier).first
  end

  def prev_item
    Item.where(:collection_id => self.collection).order(:identifier).where('identifier < ?', self.identifier).last
  end

  def citation
    cite = ""
    if collector
      cite += "#{collector.name} (collector)"
    end
    item_agents.group_by(&:user).map do |user, ias|
      cite += ", " unless cite == ""
      cite += "#{user.name} (#{ias.map(&:agent_role).map(&:name).join(', ')})"
    end
    cite += ", #{originated_on.year}" if originated_on
    cite += '; ' unless cite == ""
    cite += "<i>#{sanitize(title)}</i>, "
    last = essence_types.count - 1
    essence_types.each_with_index do |type, index|
        cite += type
        if index != last
            cite += "/"
        else
            cite += ", "
        end
    end
    cite += " #{Date.today}."
    if doi
      cite += " DOI: #{doi}"
    else
      cite += " #{full_path}"
    end
    cite
  end

  def has_coordinates
    (north_limit && north_limit != 0) ||
    (south_limit && south_limit != 0) ||
    (west_limit && west_limit != 0) ||
    (east_limit && east_limit != 0)
  end

  def csv_countries
    countries.map(&:name).join(';')
  end

  def csv_content_languages
    content_languages.map(&:name).join(';')
  end

  def csv_subject_languages
    subject_languages.map(&:name).join(';')
  end

  def csv_data_categories
    data_categories.map(&:name).join(';')
  end

  def csv_item_agents
    result = ""
    item_agents.each do |agent|
      result += "#{agent.user.name} (#{agent.agent_role.name});"
    end
    result
  end

  def csv_filenames
    essences.map(&:filename).join(';')
  end

  def csv_mimetypes
    essences.map(&:mimetype).join(';')
  end

  def csv_fps_values
    essences.map(&:fps).join(';')
  end

  def csv_samplerates
    essences.map(&:samplerate).join(';')
  end

  def csv_channel_counts
    essences.map(&:channels).join(';')
  end

  # OAI-MPH mappings for OLAC
  # If we need to later on we can generate the XML directly
  # TODO
  # - The <request> header doesn't have the params to the request as XML attributes
  def to_olac
    xml = ::Builder::XmlMarkup.new
    xml.tag! 'olac:olac', OAI::Provider::Metadata::Olac.instance.header_specification do
      xml.tag! 'dc:title', title

      xml.tag! 'dc:identifier', full_identifier
      xml.tag! 'dc:identifier', "http://catalog.paradisec.org.au/repository/#{collection.identifier}/#{identifier}", 'xsi:type' => 'dcterms:URI' unless external?
      xml.tag! 'dc:identifier', url if url?

      xml.tag! 'dc:subject', 'xsi:type' => 'olac:linguistic-field', 'olac:code' => 'language_documentation'

      if originated_on
        xml.tag! 'dcterms:created', originated_on, 'xsi:type' => 'dcterms:W3CDTF'
        xml.tag! 'dc:date', originated_on, 'xsi:type' => 'dcterms:W3CDTF'
      end

      essences.each do |essence|
        unless /PDSC_ADMIN/.match(essence.filename)
          xml.tag! 'dcterms:tableOfContents', "http://catalog.paradisec.org.au/repository/#{collection.identifier}/#{identifier}/#{essence.filename}", 'xsi:type' => 'dcterms:URI'
        end
      end

      if collector
        xml.tag! 'dc:contributor', collector_name, 'xsi:type' => 'olac:role', 'olac:code' => 'compiler'
      end

      item_agents.each do |agent|
        xml.tag! 'dc:contributor', agent.user.name, 'xsi:type' => 'olac:role', 'olac:code' => agent.agent_role.name
      end

      subject_languages.each do |language|
        xml.tag! 'dc:subject', 'xsi:type' => 'olac:language', 'olac:code' => language.code
      end
      content_languages.each do |language|
        xml.tag! 'dc:language', 'xsi:type' => 'olac:language', 'olac:code' => language.code
      end

      format = ""
      format += "Digitised: #{digitised_on? ? 'yes' : 'no'}"
      format += "\nMedia: #{original_media}" unless original_media.blank?
      format += "\nAudio Notes: #{ingest_notes}" unless ingest_notes.blank?
      xml.tag! 'dc:format', format
      countries.each do |country|
        xml.tag! 'dc:coverage', country.code, 'xsi:type' => 'dcterms:ISO3166'
      end

      if has_coordinates
        location = ""
        location += "northlimit=#{north_limit}; southlimit=#{south_limit}; "
        location += "westlimit=#{west_limit}; eastlimit=#{east_limit}"
        xml.tag! 'dc:coverage', location,  'xsi:type' => 'dcterms:Box'
      end

      item_data_categories.each do |cat|
        case cat.data_category.name
        when 'historical reconstruction', 'historical_text'
          xml.tag! 'dc:subject', 'xsi:type' => 'olac:linguistic-field',  'olac:code' => 'historical_linguistics'
        when 'language description'
          xml.tag! 'dc:type', 'xsi:type' => 'olac:linguistic-type', 'olac:code' => 'language_description'
          xml.tag! 'dc:subject', 'xsi:type' => 'olac:linguistic-field',  'olac:code' => 'language_documentation'
        when 'lexicon'
          xml.tag! 'dc:type', 'xsi:type' => 'olac:linguistic-type', 'olac:code' => 'lexicon'
          xml.tag! 'dc:subject', 'xsi:type' => 'olac:linguistic-field',  'olac:code' => 'lexicography'
        when 'primary text'
          xml.tag! 'dc:type', 'xsi:type' => 'olac:linguistic-type', 'olac:code' => 'primary_text'
          xml.tag! 'dc:subject', 'xsi:type' => 'olac:linguistic-field',  'olac:code' => 'text_and_corpus_linguistics'
        when 'song'
          xml.tag! 'dc:subject', ' xsi:type' => 'olac:discourse-type', 'olac:code' => 'singing'
        when 'typological analysis'
          xml.tag! 'dc:subject', cat.data_category.name, 'xsi:type' => 'olac:linguistic-field' , 'olac:code' => 'typology'
        when 'photo'
          xml.tag! 'dc:type', 'Image', 'xsi:type' => 'dcterms:DCMIType'
        when 'moving image'
          xml.tag! 'dc:type', 'MovingImage', 'xsi:type' => 'dcterms:DCMIType'
        when 'sound'
          xml.tag! 'dc:type', 'Sound', 'xsi:type' => 'dcterms:DCMIType'
        when 'instrumental music'
          xml.tag! 'dc:type', 'instrumental music'
        else
          # ignore
        end
      end

      if access_condition
        access = access_condition.name
        access += ", #{access_narrative}" if !access_narrative.blank?
        xml.tag! 'dcterms:accessRights', access
        xml.tag! 'dc:rights', access_condition.name
      end

      xml.tag! 'dcterms:bibliographicCitation', strip_tags(citation)
      xml.tag! 'dc:description', (description + ". Language as given: #{language}")
    end
    xml.target!
  end

  def to_param
    identifier
  end

  # ensure the collection mentions all countries and languages present in the item
  def update_collection_countries_and_languages
    collection_updated = false

    new_item_countries = countries - collection.countries
    if new_item_countries.any?
      collection.countries.concat new_item_countries
      collection_updated = true
    end

    new_languages = Set.new
    new_languages += content_languages
    new_languages += subject_languages
    new_languages -= collection.languages
    if new_languages.any?
      collection.languages.concat new_languages.to_a
      collection_updated = true
    end

    if collection_updated
      collection.save
    end
  end
end
