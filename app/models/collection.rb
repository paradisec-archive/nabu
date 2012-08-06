class Collection < ActiveRecord::Base
  has_paper_trail
  nilify_blanks

  belongs_to :collector, :class_name => "User"
  belongs_to :operator, :class_name => "User"
  belongs_to :university
  belongs_to :field_of_research
  belongs_to :access_condition

  has_many :items, :dependent => :restrict
  has_many :collection_languages, :dependent => :destroy
  has_many :languages, :through => :collection_languages, :validate => true

  has_many :collection_countries, :dependent => :destroy
  has_many :countries, :through => :collection_countries, :validate => true

  has_many :collection_admins, :dependent => :destroy
  has_many :admins, :through => :collection_admins, :validate => true, :source => :user

  # require presence of these three fields
  validates :identifier, :presence => true, :uniqueness => true,
            :format => { :with => /^[a-zA-Z0-9_]*$/, :message => "error - only letters and numbers and '_' allowed" }
  validates :title, :presence => true
  validates :collector_id, :presence => true

  validates :latitude, :numericality => {:greater_than_or_equal_to => -90, :less_then_or_equal_to => 90}, :allow_nil => true
  validates :longitude, :numericality => {:greater_than_or_equal_to => -180, :less_then_or_equal_to => 180}, :allow_nil => true
  validates :zoom, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0, :less_than => 22}, :allow_nil => true

  attr_reader :bulk_edit_append_country_ids, :bulk_edit_append_language_ids, :bulk_edit_append_admin_ids

  attr_accessible :identifier, :title, :description, :region,
                  :latitude, :longitude, :zoom,
                  :collector_id, :operator_id, :university_id, :field_of_research_id,
                  :language_ids, :country_ids, :admin_ids,
                  :access_condition_id,
                  :access_narrative, :metadata_source, :orthographic_notes, :media, :comments,
                  :complete, :private, :tape_location, :deposit_form_received,
                  :bulk_edit_append_country_ids, :bulk_edit_append_language_ids, :bulk_edit_append_admin_ids

  paginates_per 10

  delegate :name, :to => :university, :prefix => true, :allow_nil => true
  delegate :name, :to => :collector, :prefix => true, :allow_nil => true
  delegate :name, :to => :operator, :prefix => true, :allow_nil => true
  delegate :name, :to => :access_condition, :prefix => true, :allow_nil => true

  def self.sortable_columns
    %w{identifier title university_name collector_name created_at}
  end

  searchable do
    # Thins we want to perform full text search on
    text :title
    text :identifier
    text :university_name
    text :collector_name
    text :region
    text :description
    text :operator_name
    text :access_condition_name
    text :field_of_research do
      field_of_research.name
    end
    text :languages do
      languages.map(&:name)
    end
    text :countries do
      countries.map(&:name)
    end
    text :access_narrative
    text :metadata_source
    text :orthographic_notes
    text :media
    text :comments
    text :tape_location

    # Link models for faceting
    integer :collector_id, :references => User
    integer :language_ids, :references => Language, :multiple => true
    integer :country_ids, :references => Country, :multiple => true

    # Things we want to sort or use :with on
    integer :id
    string :title
    string :identifier
    string :university_name
    string :collector_name
    string :region
    string :languages, :multiple => true do
      languages.map(&:name)
    end
    string :countries, :multiple => true do
      countries.map(&:name)
    end
    float :latitude
    float :longitude
    integer :zoom
    boolean :complete
    boolean :private
    boolean :deposit_form_received
    time :created_at
  end

  def to_param
    identifier
  end
end
