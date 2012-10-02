require 'nokogiri'
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

    @items = @collection.items.order(:identifier).page(params[:items_page]).per(params[:items_per_page])
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

  def new_from_exsite9
    @collection = Collection.new
  end

  def create_from_exsite9
    # get XML data
    data = params[:collection][:exsite9].read
    # parse XML file
    doc  = Nokogiri::XML data
    puts doc.errors
    if doc.errors.count > 0
      flash[:error] = "ERROR: Unable to parse XML file (#{doc.errors.join(',')})."
      render 'new_from_exsite9'
      return
    end
    @collection = Collection.new
    flash[:notice] = ""

    # get collection information =======
    project_info = doc.xpath('//project_info')
    if !project_info[0]
      flash[:error] = "ERROR: Not an ExSite9 file."
      render 'new_from_exsite9'
      return
    end

    # is it a collection?
    collectionType = project_info[0]['collectionType']
    if collectionType != "Collection"
      flash[:error] = "ERROR: ExSite9 file does not contains collection information (collectionType = #{collectionType})."
      render 'new_from_exsite9'
      return
    end

    # collection identifier
    collectionId = project_info[0]['identifier']
    coll = Collection.find_by_identifier(collectionId)
    unless coll.nil?
      flash[:error] = "ERROR: Not a new collection #{collectionId} - can't overwrite."
      render 'new_from_exsite9'
      return
    end
    @collection.identifier = collectionId

    # collection title
    @collection.title = project_info[0].xpath('//projectName').first.content

    # description
    @collection.description = project_info[0].xpath('//description').first.content

    # collector
    coll_name = project_info[0].xpath('//name').first.content
    last_name, first_name = coll_name.split(/, /, 2)
    if first_name.blank?
      first_name, last_name = coll_name.split(/ /, 2)
    end
    collector = User.first(:conditions => ["first_name = ? AND last_name = ?", first_name, last_name])
    if collector.nil?
      flash[:error] = "ERROR: Collector #{first_name} #{last_name} not found."
      render 'new_from_exsite9'
      return
    end
    @collection.collector = collector

    # institution
    coll_uni = project_info[0].xpath('//institution').first.content
    university = University.find_by_name(coll_uni)
    if university.nil?
      flash[:notice] += "Note: institution '#{coll_uni}' ignored<br/>" unless coll_uni.blank?
    else
      @collection.university = university
    end

    # access rights
    coll_access = project_info[0].xpath('//accessRights').first.content
    access_cond = AccessCondition.find_by_name(coll_access)
    if access_cond.nil?
      flash[:notice] += "Note: accessRight '#{coll_access}' ignored<br/>" unless coll_access.blank?
    else
      @collection.access_condition = access_cond
    end

    # access narrative
    @collection.access_narrative = project_info[0].xpath('//rightsStatement').first.content

    # field or research
    coll_for = project_info[0].xpath('//fieldOfResearch').first.content
    field_of_research = FieldOfResearch.find_by_identifier(coll_for.split(/ - /))
    if field_of_research.nil?
      flash[:notice] += "Note: fieldOfResearch '#{coll_for}' ignored<br/>" unless coll_for.blank?
    else
      @collection.field_of_research = field_of_research
    end

    # region or village
    @collection.region = project_info[0].xpath('//placeOrRegionName').first.content

    # fundingBody
    coll_body = project_info[0].xpath('//fundingBody').first.content
    funding_body = FundingBody.find_by_name(coll_body)
    if funding_body.nil?
      flash[:notice] += "Note: funding_body '#{funding_body}' ignored<br/>" unless coll_body.blank?
    else
      @collection.funding_body = funding_body
    end

    # grant_identifier
    @collection.grant_identifier = project_info[0].xpath('//grantID').first.content

#    entries.each do |entry|
#      item = @collection.build_item
#      item.title = entry['title']
#    end
    @collection.identifier = ""
    if @collection.valid?
      @collection.save!
      flash[:notice] += "SUCCESS: Collection created"
      redirect_to @collection
    else
      render 'new_from_exsite9'
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
      all_of do
        with(:north_limit).less_than params[:north_limit] if params[:north_limit]
        with(:south_limit).greater_than params[:south_limit] if params[:south_limit]
        if params[:west_limit].to_i >= params[:east_limit].to_i
          with(:west_limit).greater_than params[:west_limit] if params[:west_limit]
          with(:east_limit).less_than params[:east_limit] if params[:east_limit]
        else
          with(:west_limit).less_than params[:west_limit] if params[:west_limit]
          with(:east_limit).greater_than params[:east_limit] if params[:east_limit]
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
