class ItemsController < ApplicationController
  before_filter :find_by_full_identifier, :only => [:show, :edit, :create, :update]
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
  end

  def show
    @num_files = @item.essences.length
    @files = @item.essences.page(params[:files_page]).per(params[:files_per_page])

    respond_to do |format|
      format.html
      format.xml do
        if params[:xml_type]
          render :template => "items/show.#{params[:xml_type]}.xml.haml"
        else
          render :template => "items/show"
        end
      end
    end
  end

  def create
    tidy_params
    if @item.save
      flash[:notice] = 'Item was successfully created.'
      redirect_to @item
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    tidy_params
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

    do_search
  end


  def bulk_update
    tidy_params

    # FIXME SECURITY - Should be current_user.items
    @items = current_user.items.find params[:item_ids].split(' ')

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
  def tidy_params
    @item.country_ids = params[:item].delete(:country_ids).split(/,/)
    @item.subject_language_ids = params[:item].delete(:subject_language_ids).split(/,/)
    @item.content_language_ids = params[:item].delete(:content_language_ids).split(/,/)

    params[:item][:item_agents_attributes] ||= {}
    params[:item][:item_agents_attributes].each_pair do |id, iaa|
      name = iaa['user_id']
      next unless name =~ /^NEWCONTACT:/
      name = name.gsub(/^NEWCONTACT:/, '')

      last_space = name.rindex(' ')
      if last_space
        first_name = name[0..last_space-1]
        last_name = name[last_space+1..-1]
      else
        first_name = name
      end

      contact = User.where(:first_name => first_name, :last_name => last_name).first
      if contact.nil?
        random_string = SecureRandom.base64(16)
        contact = User.create!({
          :first_name => first_name,
          :last_name => last_name,
          :password => random_string,
          :password_confirmation => random_string,
          :contact_only => true}, :as => :contact_only)
      end
      iaa['user_id'] = contact.id
    end
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
          if params["blank_#{field.name}"].present?
            with field.name.to_sym, nil
          end
        when Sunspot::Type::IntegerType
          with field.name, params[field.name]
        when Sunspot::Type::BooleanType
          with field.name, params[field.name] == 'true' ? true : false
        end
      end

      with(:private, false) unless current_user.admin?
      sort_column.each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end
  end

  def find_by_full_identifier
    collection_identifier, item_identifier = params[:id].split (/-/)
    @collection = Collection.find_by_identifier collection_identifier
    @item = @collection.items.find_by_identifier item_identifier
  end

end
