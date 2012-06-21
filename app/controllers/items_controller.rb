class ItemsController < ApplicationController
  load_and_authorize_resource :collection
  load_and_authorize_resource :item, :through => :collection, :shallow => true

  def index
    if params[:clear]
      params.delete(:search)
      redirect_to items_path
    end

    @search = Item.solr_search do
      fulltext params[:search]
      facet :content_language_ids, :country_ids, :collector_id

      with(:collector_id, params[:collector_id]) if params[:collector_id].present?
      with(:content_language_ids, params[:language_id]) if params[:language_id].present?
      with(:country_ids, params[:country_id]) if params[:country_id].present?

      with(:private, false) unless current_user && current_user.admin?
      sort_column.each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end
  end

  def advanced_search
    # authorize! :advanced_search, Item
    do_search
  end

  def new
    build_associations
  end

  def show
  end

  def create
    if @item.save
      flash[:notice] = 'Item was successfully created.'
      redirect_to @item
    else
      render :action => 'new'
    end
  end

  def edit
    build_associations
  end

  def update
    if @item.update_attributes(params[:item])
      flash[:notice] = 'Item was successfully updated.'
      redirect_to @item
    else
      render :action => "edit"
    end
  end

  def bulk_edit
    @item = Item.new
    @item.collection = Collection.new
    build_associations

    do_search
  end


  def bulk_update
    @items = Item.where :id => params[:item_ids].split(' ')

    update_params = params[:item].delete_if {|k, v| v.blank?}

    # Collect the fields we are appending to
    appendable = {}
    params[:item].each_pair do |k, v|
      if k =~ /^bulk_edit_append_(.*)/
        appendable[$1] = params[:item].delete $1
        params[:item].delete k
      end
    end

    invalid_record = false
    @items.each do |item|
      appendable.each_pair do |k, v|
        params[:item][k.to_sym] = item.send(k) + v
      end
      unless item.update_attributes(params[:item])
        invalid_record = true
        @item = item
        break
      end
    end

    if invalid_record
      do_search
      render :action => "bulk_edit"
    else
      flash[:notice] = 'Items were successfully updated.'
      redirect_to advanced_search_items_path + "?#{params[:original_search_params]}"
    end
  end

  private
  def build_associations
    @item.item_countries.build
    @item.item_subject_languages.build
    @item.item_content_languages.build
    @item.item_admins.build
    @item.item_agents.build
  end

  def do_search
    @fields = Sunspot::Setup.for(Item).fields
    @text_fields = Sunspot::Setup.for(Item).all_text_fields
    @search = Item.solr_search do
      Sunspot::Setup.for(Item).all_text_fields.each do |field|
        next if params[field.name].blank?
        keywords params[field.name], :fields => [field.name]
      end

      Sunspot::Setup.for(Item).fields.each do |field|
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

      with(:private, false) unless current_user.admin?
      order_by sort_column, sort_direction
      paginate :page => params[:page], :per_page => params[:per_page]
    end
  end
end
