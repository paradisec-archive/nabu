require 'exsite9'
require 'nabu_spreadsheet'

class CollectionsController < ApplicationController
  load_and_authorize_resource :find_by => :identifier, :except => [:search, :advanced_search, :bulk_update, :bulk_edit]
  authorize_resource :only => [:advanced_search, :bulk_update, :bulk_edit]

  def search
    if params[:clear]
      params.delete(:search)
      redirect_to search_collections_path
      return
    end

    @search = Collection.solr_search do
      fulltext params[:search]
      facet :language_ids, :country_ids
      facet :collector_id, :limit => 100

      with(:language_ids, params[:language_id]) if params[:language_id].present?
      with(:country_ids, params[:country_id]) if params[:country_id].present?
      with(:collector_id, params[:collector_id]) if params[:collector_id].present?

      with(:private, false) unless current_user && current_user.admin?
      sort_column(Collection).each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end

    respond_to do |format|
      format.html
      if can? :search_csv, Collection
        format.csv do
          fields = [:identifier, :title, :description, :collector_name, :operator_name, :university_name, :csv_languages, :csv_countries, :region, :north_limit, :south_limit, :west_limit, :east_limit, :field_of_research_name, :grant_identifier, :funding_body_name, :access_condition_name, :access_narrative]
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
    @num_items = @collection.items.count
    @num_items_ready = @collection.items.where{ digitised_on != nil }.count
    @num_essences = Essence.where(:item_id => @collection.items).count

    @items = @collection.items.page(params[:items_page]).per(params[:items_per_page])

    if params[:sort]
      @items = @items.order("#{params[:sort]} #{params[:direction]}")
    else
      @items = @items.order(:identifier)
    end
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
      render :action => 'new'
    end
  end

  def edit
    @num_items = @collection.items.count
    @num_items_ready = @collection.items.where{ digitised_on != nil }.count
    @num_essences = Essence.where(:item_id => @collection.items).count

    @items = @collection.items.order(:identifier).page(params[:items_page]).per(params[:items_per_page])
  end

  def destroy
    begin
      @collection.destroy
      undo_link = view_context.link_to("undo", revert_version_path(@collection.versions.last), :method => :post, :class => 'undo')
      flash[:notice] = "Collection removed successfully (#{undo_link})."
      redirect_to search_collections_path
    rescue ActiveRecord::DeleteRestrictionError
      flash[:error] = "Collection has items and cannot be removed."
      redirect_to @collection
    end
  end

  def update
    if @collection.update_attributes(params[:collection])
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
        if collection.send(k).nil?
          params[:collection][k.to_sym] = v unless v.blank?
        else
          params[:collection][k.to_sym] = collection.send(k) + v unless v.blank?
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
      do_search
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
    # get XSL data
    data = params[:collection][:metadata].read
    # parse XML file as Spreadsheet
    sheet = Nabu::NabuSpreadsheet.new
    sheet.parse data, current_user

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
        end
      end
      flash[:notice] = "SUCCESS: #{saved_items} items created for collection #{@collection.identifier}<br/>"
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

      # Blank Search
      Sunspot::Setup.for(Collection).fields.each do |field|
        next unless field.name =~ /_blank$/
        next unless params[field.name] == '1'
        with field.name, true
      end

      with(:private, false) unless current_user && current_user.admin?
      sort_column(Collection).each do |c|
        order_by c, sort_direction
      end
      paginate :page => params[:page], :per_page => params[:per_page]
    end
  end
end
