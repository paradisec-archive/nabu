class CollectionsController < ApplicationController
  load_and_authorize_resource

  def index
    if params[:clear]
      params.delete(:search)
      redirect_to collections_path
    end


    @search = Collection.solr_search do
      fulltext params[:search]
      facet :language_ids, :country_ids, :university_id

      with(:university_id, params[:university_id]) if params[:university_id].present?
      with(:language_ids, params[:language_id]) if params[:language_id].present?
      with(:country_ids, params[:country_id]) if params[:country_id].present?

      order_by sort_column, sort_direction
      paginate :page => params[:page], :per_page => params[:per_page]
    end
  end

  def advanced_search
    @fields = Sunspot::Setup.for(Collection).fields
    @text_fields = Sunspot::Setup.for(Collection).all_text_fields
    @search = Collection.solr_search do
      Sunspot::Setup.for(Collection).all_text_fields.each do |field|
        next if params[field.name].blank?
        keywords params[field.name], :fields => [field.name]
      end

      Sunspot::Setup.for(Collection).fields.each do |field|
        next if params[field.name].blank?
        case field.type
        when Sunspot::Type::StringType
          # Do nothing. Should be covered by text field above
        when Sunspot::Type::IntegerType
          with field.name, params[field.name]
        when Sunspot::Type::BooleanType
          with field.name, params[field.name] == 'true' ? true : false
        end
      end
    end

      #fulltext params[:search]
      #facet :language_ids, :country_ids, :university_id
#
#      with(:university_id, params[:university_id]) if params[:university_id].present?
#      with(:language_ids, params[:language_id]) if params[:language_id].present?
#      with(:country_ids, params[:country_id]) if params[:country_id].present?
#
#      order_by sort_column, sort_direction
#      paginate :page => params[:page], :per_page => params[:per_page]
#    end

  end

  def new
    build_associations
  end

  def show
    @num_items = @collection.items.count
    @num_items_ready = @collection.items.where{ digitised_on != nil }.count
    @num_essences = Essence.where(:item_id => @collection.items).count
  end

  def create
    if @collection.save
      flash[:notice] = 'Collection was successfully created.'
      redirect_to @collection
    else
      render :action => 'new'
    end
  end

  def edit
    build_associations
  end

  def update
    if @collection.update_attributes(params[:collection])
      flash[:notice] = 'Collection was successfully updated.'
      redirect_to @collection
    else
      render :action => "edit"
    end
  end

  private
  def build_associations
    @collection.collection_languages.build
    @collection.collection_countries.build
    @collection.collection_admins.build
  end

end
