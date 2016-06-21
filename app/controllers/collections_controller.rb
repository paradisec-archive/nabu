require 'exsite9'
require 'nabu_spreadsheet'

class CollectionsController < ApplicationController
  include HasReturnToLastSearch

  before_filter :tidy_params, :only => [:create, :update, :bulk_update]
  load_and_authorize_resource :find_by => :identifier, :except => [:return_to_last_search, :search, :advanced_search, :bulk_update, :bulk_edit]
  authorize_resource :only => [:advanced_search, :bulk_update, :bulk_edit]

  def search
    @page_title = 'Nabu - Collections'
    if params[:clear]
      params.delete(:search)

      redirect_to search_collections_path
      return
    end

    @search = Collection.solr_search(include: [:collector, :countries, :languages, :university]) do
      fulltext params[:search]
      facet :language_ids, :country_ids
      facet :collector_id, :limit => 100

      with(:language_codes, params[:language_code]) if params[:language_code].present?
      with(:country_codes, params[:country_code]) if params[:country_code].present?
      with(:collector_id, params[:collector_id]) if params[:collector_id].present?

      unless current_user && current_user.admin?
        any_of do
          with(:private, false)
          with(:admin_ids, current_user.id) if current_user
          with(:item_admin_ids, current_user.id) if current_user
          with(:item_user_ids, current_user.id) if current_user
        end
      end
      sort_column(Collection).each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end

    respond_to do |format|
      format.html
      if can? :search_csv, Collection
        # This uses attributes that an HTML request doesn't use. Some attributes here ought to be eagerly loaded but aren't.
        format.csv do
          fields = [:identifier, :title, :description, :collector_name, :operator_name, :university_name, :csv_languages, :csv_countries, :region, :north_limit, :south_limit, :west_limit, :east_limit, :field_of_research_name, :csv_full_grant_identifiers, :funding_body_names, :access_condition_name, :access_narrative]
          send_data @search.results.to_csv({:headers => fields, :only => fields}, :col_sep => ','), :type => "text/csv; charset=utf-8; header=present"
        end
      end
    end
  end

  def advanced_search
    @page_title = 'Nabu - Advanced Search Collections'
    @search = build_advanced_search(params)
    respond_to do |format|
      format.html
      if can? :search_csv, Collection
        # This uses attributes that an HTML request doesn't use. Some attributes here ought to be eagerly loaded but aren't.
        format.csv do
          fields = [:identifier, :title, :description, :collector_name, :operator_name, :university_name, :csv_languages, :csv_countries, :region, :north_limit, :south_limit, :west_limit, :east_limit, :field_of_research_name, :csv_full_grant_identifiers, :funding_body_names, :access_condition_name, :access_narrative]
          send_data @search.results.to_csv({:headers => fields, :only => fields}, :col_sep => ','), :type => "text/csv; charset=utf-8; header=present"
        end
      end
    end
  end

  def new
    @page_title = 'Nabu - Add New Collection'
  end

  def show
    @num_items = @collection.items.count
    @num_items_ready = @collection.items.where{ digitised_on != nil }.count
    @num_essences = Essence.where(:item_id => @collection.items).count

    @items = @collection.items.includes(:access_condition, :collection).page(params[:items_page]).per(params[:items_per_page])

    if params[:sort]
      @items = @items.order("#{params[:sort]} #{params[:direction]}")
    else
      @items = @items.order(:identifier)
    end
    @page_title = "Nabu - #{@collection.title}"
  end

  def create
    # Make the depositor an admin
    unless @collection.admins.include? current_user
      @collection.admins << current_user
    end

    if @collection.save
      flash[:notice] = 'Collection was successfully created.'
      redirect_to @collection
    else
      @page_title = 'Nabu - Add New Collection'
      render :action => 'new'
    end
  end

  def edit
    @page_title = "Nabu - Edit Collection"
    @num_items = @collection.items.count

    @items = @collection.items.includes(:access_condition, :collection).order(:identifier).page(params[:items_page]).per(params[:items_per_page])
  end

  def destroy
    begin
      if params[:delete_items]
        item_destruction_errors = @collection.items.collect do |item|
          response = ItemDestructionService.new(item, true).destroy
          response[:messages][:error]
        end.uniq

        # if there are only a couple, show them, otherwise report the total number
        if item_destruction_errors.length <= 5
          item_destruction_errors = item_destruction_errors.join("<br/>\n")
        else
          item_destruction_errors = "Encountered #{item_destruction_errors.length} warnings (often caused by missing files) while deleting the collection."
          item_destruction_errors += "<br/>\n\tYou may want to contact the administrators and confirm that nothing bad happened." if item_destruction_errors.length > 10
        end

        @collection.items = []
      end

      # only remove the collection if there are no items left
      @collection.destroy unless @collection.items.any?

      if params[:delete_items]
        flash[:notice] = 'Collection and all its items removed permanently (no undo possible)'
      else
        undo_link = view_context.link_to("undo", revert_version_path(@collection.versions.last), :method => :post, :class => 'undo')
        flash[:notice] = "Collection removed successfully (#{undo_link})."
      end

      if item_destruction_errors.present?
        flash[:error] = "Some errors occurred while removing dependent items:<br/>\n#{item_destruction_errors}"
      end

      redirect_to search_collections_path
    rescue ActiveRecord::DeleteRestrictionError
      flash[:error] = 'Collection has items and cannot be removed.'
      redirect_to @collection
    end
  end

  def update
    if @collection.update_attributes(params[:collection])
      flash[:notice] = 'Collection was successfully updated.'
      redirect_to @collection
    else
      @num_items = @collection.items.count

      @items = @collection.items.order(:identifier).page(params[:items_page]).per(params[:items_per_page])
      @page_title = "Nabu - Edit Collection"
      render :action => "edit"
    end
  end

  def bulk_edit
    @page_title = 'Nabu - Collections Bulk Update'
    @collection = Collection.new

    @search = build_advanced_search(params)
  end


  def bulk_update
    @collections = Collection.accessible_by(current_ability).where :id => params[:collection_ids].split(' ')

    params[:collection].delete_if {|k, v| v.blank?}

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
        if collection.public_send(k).nil?
          params[:collection][k.to_sym] = v unless v.blank?
        else
          params[:collection][k.to_sym] = collection.public_send(k) + v unless v.blank?
        end
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
      @page_title = 'Nabu - Collections Bulk Update'
      @collection = Collection.new
      @search = build_advanced_search(params)
      render :action => 'bulk_edit'
    else
      flash[:notice] = 'Collections were successfully updated.'
      redirect_to bulk_update_collections_path + "?#{params[:original_search_params]}"
    end
  end

  def new_from_metadata
    @collection = Collection.new
  end

  def create_from_exsite9
    unless params.key?(:collection)
      @collection = Collection.new unless @collection
      flash[:error] = 'No ExSite9 file submitted'
      render 'new_from_metadata'
      return
    end
    # get XML data
    data = params[:collection][:metadata].read
    # parse XML file as ExSite9
    exsite9 = Nabu::ExSite9.new
    exsite9.parse data, current_user

    if exsite9.valid?
      @collection = exsite9.collection
      @collection.save!
      flash[:notice] ||= "SUCCESS: Collection created"
      flash[:notice] += exsite9.notices.join("<br/>") unless exsite9.notices.blank?
      redirect_to @collection
    else
      @collection = Collection.new unless @collection
      flash[:notice] = exsite9.notices.join("<br/>") unless exsite9.notices.blank?
      flash[:error] = exsite9.errors.join("<br/>") unless exsite9.errors.blank?
      render 'new_from_metadata'
    end
  end

  def create_from_spreadsheet
    unless params.key?(:collection)
      @collection = Collection.new unless @collection
      flash[:error] = 'No Spreadsheet XLS file submitted'
      render 'new_from_metadata'
      return
    end
    # get XSL data
    data = params[:collection][:metadata].read
    # parse XML file as Spreadsheet
    sheet = Nabu::NabuSpreadsheet.new_of_correct_type(data)

    if sheet.valid?
      @collection = sheet.collection
      @collection.save!
      saved_items = 0
      added_items = ""
      sheet.items.each do |item|
        if item.valid? #just making sure - even though NabuSpreadsheet already check this
          item.save!
          saved_items += 1
          added_items += "#{item.identifier}, "

          # render the template here because you can't access render in the service
          data = render_to_string :template => 'items/catalog_export.xml.haml', locals: {item: item}

          ItemCatalogService.new(item).save_file(data)
        end
      end
      flash[:notice] = "SUCCESS: #{saved_items} items created/updated for collection #{@collection.identifier}<br/>"
      flash[:notice] += sheet.notices.join("<br/>") unless sheet.notices.empty?
      flash[:notice] += "<br/>Added items: #{added_items.chomp(', ')}"

      redirect_to @collection
    else
      @collection = Collection.new unless @collection
      flash[:notice] = sheet.notices.join("<br/>") unless sheet.notices.empty?
      flash[:error] = sheet.errors.join("<br/>") unless sheet.errors.empty?
      render 'new_from_metadata'
    end
  end

  private
  def tidy_params
    if params[:collection]
      # this is used to allow grants where there is a funding body but no grant id
      if params[:collection][:grants_attributes]
        # map the collection identifier to the underlying id
        collection_id = Collection.where(identifier: params[:id]).pluck(:id).first
        grants = params[:collection][:grants_attributes]

        if params["funding_body_ids"]
          funding_body_ids = params["funding_body_ids"]
        else
          funding_body_ids = []
        end

        fbids = funding_body_ids.reject {|x| grants.collect{|y| y[:funding_body_id]}.include?(x)}

        # for each funding body that doesn't have grant ids, create an empty grant

        params[:collection][:grants_attributes].concat fbids.collect{|x| {'funding_body_id' => x, 'grant_identifier' => nil}}
        # apply the current collection to every item
        params[:collection][:grants_attributes].each{ |g| g['collection_id'] = collection_id }
      end

      if params[:collection][:collector_id] =~ /^NEWCONTACT:/
        params[:collection][:collector_id] = create_contact(params[:collection][:collector_id])
      end
    end
  end

  def build_advanced_search(params)
    Collection.solr_search(include: [:collector, :countries, :languages, :university]) do
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

      unless current_user && current_user.admin?
        any_of do
          with(:private, false)
          with(:admin_ids, current_user.id) if current_user
        end
      end
      sort_column(Collection).each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end
  end
end
