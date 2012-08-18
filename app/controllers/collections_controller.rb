class CollectionsController < ApplicationController
  load_and_authorize_resource :find_by => :identifier

  def index
    if params[:clear]
      params.delete(:search)
      redirect_to collections_path
    end

    @search = Collection.solr_search do
      fulltext params[:search]
      facet :language_ids, :country_ids, :collector_id

      with(:language_ids, params[:language_id]) if params[:language_id].present?
      with(:country_ids, params[:country_id]) if params[:country_id].present?
      with(:collector_id, params[:collector_id]) if params[:collector_id].present?

      with(:private, false) unless current_user && current_user.admin?
      sort_column.each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end
  end

  def advanced_search
    # authorize! :advanced_search, Collection
    do_search
  end

  def new
  end

  def show
    @num_items = @collection.items.count
    @num_items_ready = @collection.items.where{ digitised_on != nil }.count
    @num_essences = Essence.where(:item_id => @collection.items).count

    @items = @collection.items.page(params[:items_page]).per(params[:items_per_page])
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
    @num_items = @collection.items.count
    @num_items_ready = @collection.items.where{ digitised_on != nil }.count
    @num_essences = Essence.where(:item_id => @collection.items).count

    @items = @collection.items.page(params[:items_page]).per(params[:items_per_page])
  end

  def update
    if @collection.update_attributes(params[:collection])
      # Make the depositor an admin
      unless @collection.admins.include? current_user
        @collection.admins << current_user
        @collection.save!
      end
      flash[:notice] = 'Collection was successfully updated.'
      redirect_to @collection
    else
      render :action => "edit"
    end
  end

  def bulk_edit
    @collection = Collection.new

    do_search
  end


  def bulk_update
    @collections = Collection.accessible_by(current_ability).where :id => params[:collection_ids].split(' ')

    update_params = params[:collection].delete_if {|k, v| v.blank?}

    # Collect the fields we are appending to
    appendable = {}
    params[:collection].each_pair do |k, v|
      if k =~ /^bulk_edit_append_(.*)/
        appendable[$1] = params[:collection].delete $1 if v == "1"
        params[:collection].delete k
      end
    end

    invalid_record = false
    @collections.each do |collection|
      appendable.each_pair do |k, v|
        params[:collection][k.to_sym] = collection.send(k) + v unless v.blank?
      end
      unless collection.update_attributes(params[:collection])
        invalid_record = true
        @collection = collection
        break
      end
    end

    appendable.each_pair do |k, v|
      params[:collection][k.to_sym] = nil
      params[:collection]["bulk_edit_append_#{k}"] = v
    end

    if invalid_record
      do_search
      render :action => 'bulk_edit'
    else
      flash[:notice] = 'Collections were successfully updated.'
      redirect_to advanced_search_collections_path + "?#{params[:original_search_params]}"
    end
  end

  private
  def do_search
    @fields = Sunspot::Setup.for(Collection).fields
    @text_fields = Sunspot::Setup.for(Collection).all_text_fields
    @search = Collection.solr_search do
      # Full text search
      Sunspot::Setup.for(Collection).all_text_fields.each do |field|
        next if params[field.name].blank?
        keywords params[field.name], :fields => [field.name]
      end

      # Exact search
      Sunspot::Setup.for(Collection).fields.each do |field|
        next if params[field.name].blank?
        case field.type
        when Sunspot::Type::IntegerType
          with field.name, params[field.name]
        when Sunspot::Type::BooleanType
          with field.name, params[field.name] == 'true' ? true : false
        end
      end

      # Blank Search
      Sunspot::Setup.for(Collection).fields.each do |field|
        next unless field.name =~ /_blank$/
        next unless params[field.name] == '1'
        with field.name, true
      end

      with(:private, false) unless current_user.admin?
      sort_column.each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end
  end
end
