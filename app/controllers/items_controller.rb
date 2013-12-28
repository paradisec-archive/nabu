class ItemsController < ApplicationController
  before_filter :tidy_params, :only => [:create, :update, :bulk_update]
  load_and_authorize_resource :collection, :find_by => :identifier, :except => [:search, :advanced_search, :bulk_update, :bulk_edit]
  load_and_authorize_resource :item, :find_by => :identifier, :through => :collection, :except => [:search, :advanced_search, :bulk_update, :bulk_edit]
  authorize_resource :only => [:advanced_search, :bulk_update, :bulk_edit]

  def search
    if params[:clear]
      params.delete(:search)
      redirect_to search_items_path
      return
    end

    @search = Item.solr_search do
      fulltext params[:search].gsub(/-/, ' ') if params[:search]

      facet :content_language_ids, :country_ids
      facet :collector_id, :limit => 100

      with(:collector_id, params[:collector_id]) if params[:collector_id].present?
      with(:content_language_ids, params[:language_id]) if params[:language_id].present?
      with(:country_ids, params[:country_id]) if params[:country_id].present?

      with(:private, false) unless current_user && current_user.admin?
      sort_column(Item).each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end

    respond_to do |format|
      format.html
      if can? :search_csv, Item
        format.csv do
          fields = [:full_identifier, :title, :external, :description, :url, :collector_sortname, :operator_name, :csv_item_agents, :university_name, :language, :dialect, :csv_subject_languages, :csv_content_languages, :csv_countries, :region, :csv_data_categories, :discourse_type_name, :originated_on, :originated_on_narrative, :north_limit, :south_limit, :west_limit, :east_limit, :access_condition_name, :access_narrative]
          send_data @search.results.to_csv({:headers => fields, :only => fields}, :col_sep => ','), :type => "text/csv; charset=utf-8; header=present"
        end
      end
    end
  end

  def advanced_search
    do_search
  end

  def new
  end

  def show
    @num_files = @item.essences.length
    @files = @item.essences.page(params[:files_page]).per(params[:files_per_page])

    if params[:sort]
      @files = @files.order("#{params[:sort]} #{params[:direction]}")
    end

    respond_to do |format|
      format.html
      format.xml do
        if params[:xml_type]
          render :template => "items/show.#{params[:xml_type]}.xml.haml"
        else
          render :template => "items/show.xml.haml"
        end
      end
    end
  end

  def create
    if @item.save
      # update xml file of the item
      save_item_catalog_file(@item)

      flash[:notice] = 'Item was successfully created.'
      redirect_to [@collection, @item]
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def destroy
    begin
      @item.destroy
      undo_link = view_context.link_to("undo", revert_version_path(@item.versions.last), :method => :post, :class => 'undo')
      # remove directory and PDSC_ADMIN files on disk
      delete_directory(@item)
      flash[:notice] = "Item removed successfully (#{undo_link})."
      redirect_to @collection
    rescue ActiveRecord::DeleteRestrictionError
      flash[:error] = "Item has content files and cannot be removed."
      redirect_to [@collection, @item]
    end
  end

  def update
    @num_files = @item.essences.length
    @files = @item.essences.page(params[:files_page]).per(params[:files_per_page])

    if @item.update_attributes(params[:item])
      # update xml file of the item
      save_item_catalog_file(@item)

      flash[:notice] = 'Item was successfully updated.'
      redirect_to [@collection, @item]
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
    @items = Item.accessible_by(current_ability).where :id => params[:item_ids].split(' ')

    params[:item].delete_if {|k, v| v.blank?}

    # Collect the fields we are appending to
    appendable = {}
    params[:item].each_pair do |k, v|
      if k =~ /^bulk_edit_append_(.*)/
        appendable[$1] = params[:item].delete $1 if v == "1"
        params[:item].delete k
      end
    end

    invalid_record = false
    @items.each do |item|
      appendable.each_pair do |k, v|
        if item.send(k).nil?
          params[:item][k.to_sym] = v unless v.blank?
        else
          params[:item][k.to_sym] = item.send(k) + v unless v.blank?
        end
      end
      unless item.update_attributes(params[:item])
        invalid_record = true
        @item = item
        break
      end
      # save updated item info to xml file
      save_item_catalog_file(item)
    end

    appendable.each_pair do |k, v|
      params[:item][k.to_sym] = nil
      params[:item]["bulk_edit_append_#{k}"] = v
    end

    if invalid_record
      do_search
      render :action => 'bulk_edit'
    else
      flash[:notice] = 'Items were successfully updated.'
      redirect_to bulk_update_items_path + "?#{params[:original_search_params]}"
    end
  end

  def display
    send_file @item.path, :disposition => 'inline', :type => 'text/xml'
  end


  private
  def tidy_params
    if params[:item]
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
  end

  def do_search
    @fields = Sunspot::Setup.for(Item).fields
    @text_fields = Sunspot::Setup.for(Item).all_text_fields
    @search = Item.solr_search do
      # Full text search
      Sunspot::Setup.for(Item).all_text_fields.each do |field|
        next if params[field.name].blank?
        keywords params[field.name], :fields => [field.name]
      end

      # Exact search
      Sunspot::Setup.for(Item).fields.each do |field|
        next if params[field.name].blank?
        case field.type
        when Sunspot::Type::IntegerType
          with field.name, params[field.name]
        when Sunspot::Type::BooleanType
          with field.name, params[field.name] =~ /^true|1$/ ? true : false
        when Sunspot::Type::TimeType
          with(field.name).between (Time.parse(params[field.name]).beginning_of_day)..(Time.parse(params[field.name]).end_of_day)
        else
          p "WARNING can't search: #{field.type} #{field.name}"
        end
      end

      # GEO Is special
      if params[:north_limit]
        all_of do
          with(:north_limit).less_than    params[:north_limit]
          with(:north_limit).greater_than params[:south_limit]

          with(:south_limit).less_than    params[:north_limit]
          with(:south_limit).greater_than params[:south_limit]

          if params[:west_limit] <= params[:east_limit]
            with(:west_limit).greater_than params[:west_limit]
            with(:west_limit).less_than    params[:east_limit]

            with(:east_limit).greater_than params[:west_limit]
            with(:east_limit).less_than    params[:east_limit]
          else
            any_of do
              all_of do
                with(:west_limit).greater_than params[:west_limit]
                with(:west_limit).less_than    180
              end
              all_of do
                with(:west_limit).less_than    params[:east_limit]
                with(:west_limit).greater_than(-180)
              end
            end
            any_of do
              all_of do
                with(:east_limit).greater_than params[:west_limit]
                with(:east_limit).less_than    180
              end
              all_of do
                with(:east_limit).less_than    params[:east_limit]
                with(:east_limit).greater_than(-180)
              end
            end
          end
        end
      end

      with(:private, false) unless current_user && current_user.admin?
      sort_column(Item).each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end
  end

  def find_by_full_identifier
    if params[:id]
      collection_identifier, item_identifier = params[:id].split(/-/)
      @collection = Collection.find_by_identifier collection_identifier
      @item = @collection.items.find_by_identifier item_identifier
    elsif params[:collection_id]
      @collection = Collection.find_by_identifier params[:collection_id]
    end
  end

  def save_item_catalog_file(item)
    if !File.directory?(Nabu::Application.config.archive_directory)
      FileUtils.mkdir_p(Nabu::Application.config.archive_directory)
    end
    # make sure the archive directory for the collection and item exist
    directory = Nabu::Application.config.archive_directory +
                "#{item.collection.identifier}/#{item.identifier}/"

    FileUtils.mkdir_p(directory)
    # save file
    @item = item
    data = render_to_string :template => 'items/show.xml.haml'
    file = directory + "#{item.full_identifier}-CAT-PDSC_ADMIN.xml"
    file = File.open(file, 'w') {|f| f.write(data)}
  end

  def delete_directory(item)
    return if !File.directory?(Nabu::Application.config.archive_directory)
    directory = Nabu::Application.config.archive_directory +
                "#{item.collection.identifier}/#{item.identifier}/"
    return if !File.directory?(directory)
    # delete all PDSC_ADMIN files
    file = directory + "#{item.full_identifier}*-PDSC_ADMIN.*"
    FileUtils.rm_f(file)
    FileUtils.rmdir(directory)
  end
end
