class ItemsController < ApplicationController
  include HasReturnToLastSearch
  include ItemQueryBuilder

  before_filter :tidy_params, :only => [:create, :update, :bulk_update]
  load_and_authorize_resource :collection, :find_by => :identifier, :except => [:return_to_last_search, :search, :advanced_search, :bulk_update, :bulk_edit, :new_report, :send_report, :report_sent]
  load_and_authorize_resource :item, :find_by => :identifier, :through => :collection, :except => [:return_to_last_search, :search, :advanced_search, :bulk_update, :bulk_edit, :new_report, :send_report, :report_sent]
  authorize_resource :only => [:advanced_search, :bulk_update, :bulk_edit, :new_report, :send_report, :report_sent]

  def search
    if params[:clear]
      params.delete(:search)
      redirect_to search_items_path
      return
    end

    @search = ItemSearchService.build_solr_search(params, current_user)
    session[:result_ids] = @search.hits.map{|h|h.stored(:full_identifier)}

    @page_title = 'Nabu - Item Search'
    respond_to do |format|
      format.html
      if can? :search_csv, Item
        format.csv do
          stream_csv(:basic)
        end
      end
    end
  end

  def advanced_search
    @page_title = 'Nabu - Advanced Item Search'
    build_advanced_search(params)
    respond_to do |format|
      format.html
      if can? :search_csv, Item
        format.csv do
          stream_csv(:advanced)
        end
      end
    end
  end

  def new
    @page_title = 'Nabu - Add New Item'

    #For creating duplicate items
    if params[:id]
      existing = Item.find(params[:id])
      attributes = existing.attributes.select do |attr, _value|
        Item.column_names.include?(attr.to_s)
      end

      @item.assign_attributes(attributes, :without_protection => true)

      # loop through and clone the association contents as well, otherwise it gets emptied out
      Item::DUPLICATABLE_ASSOCIATIONS.each do |assoc|
        existing.public_send(assoc).each { |a| @item.public_send(assoc) << a }
      end
    end

  end

  def show
    @page_title = "Nabu - #{@item.title}"
    @num_files = @item.essences.length
    @files = @item.essences.page(params[:files_page]).per(params[:files_per_page])

    if params[:sort]
      @files = @files.order("#{params[:sort]} #{params[:direction]}")
    else
      @files = @files.order(:filename)
    end

    respond_to do |format|
      format.html
      format.xml do
        if params[:xml_type]
          render :template => "items/show.#{params[:xml_type]}", formats: [:xml], handlers: [:haml]
        else
          render :template => "items/show", formats: [:xml], handlers: [:haml]
        end
      end
    end
  end

  def data
    authorize! :read, User # require logged in user

    audio_values = {}
    documents_values = []
    eaf_values = {}
    flextext_values = {}
    images_values = {}
    ixt_values = {}
    trs_values = {}
    video_values = {}
    @item.essences.each do |essence|
      essence_filename = essence.filename
      essence_extension = File.extname(essence_filename)[1..-1]
      essence_basename = File.basename(essence_filename, "." + essence_extension)
      repository_essence_url = repository_essence_url(@collection, @item, essence.filename)
      case essence_extension
      when "eaf"
        eaf_values[essence_basename] ||= []
        eaf_values[essence_basename] << repository_essence_url
      when "flextext"
        flextext_values[essence_basename] ||= []
        flextext_values[essence_basename] << repository_essence_url
      when "ixt"
        ixt_values[essence_basename] ||= []
        ixt_values[essence_basename] << repository_essence_url
      when "trs"
        trs_values[essence_basename] ||= []
        trs_values[essence_basename] << repository_essence_url
      # ASSUMPTION: webm is a video, not an audio, based on email from Nick Thien.
      # ENHANCEMENT: Using essence.mimetype would be more robust.
      # when "mp3", "webm", "ogg", "oga"
      when "mp3", "ogg", "oga"
        unless audio_values.key?(essence_basename)
          spectrum_url = repository_essence_url.gsub("." + essence_extension, "-spectrum-PDSC_ADMIN.jpg")
          # Copied from Essence#path and Essence#full_identifier.
          unless File.exist?(Nabu::Application.config.archive_directory + essence.item.collection.identifier + '/' + essence.item.identifier + '/' + File.basename(spectrum_url))
            spectrum_url = nil
          end
          audio_values[essence_basename] = {
            "files" => [],
            "spectrum" => spectrum_url
          }
        end
        audio_values[essence_basename]["files"] << repository_essence_url
      when "mp4", "webm", "ogg", "ogv", "mov", "webm"
        video_values[essence_basename] ||= []
        video_values[essence_basename] << repository_essence_url
      when "jpg", "jpeg", "png"
        thumbnail_url = repository_essence_url.gsub("." + essence_extension, "-thumb-PDSC_ADMIN.jpg")

        # Copied from Essence#path and Essence#full_identifier.
        unless File.exist?(Nabu::Application.config.archive_directory + essence.item.collection.identifier + '/' + essence.item.identifier + '/' + File.basename(thumbnail_url))
          thumbnail_url = nil
        end

        # REQUIREMENTS: There are scenarios where multiple originals have the same essence basename. Is that ok as far as the player is concerned?
        unless images_values.key?(essence_basename)
          images_values[essence_basename] = {
            "originals" => [],
            "thumbnail" => thumbnail_url
          }
        end
        images_values[essence_basename]["originals"] << repository_essence_url
      when "pdf"
        documents_values << repository_essence_url
      else
        # Ignore the file
      end
    end
    response_value = {
      "audio" => audio_values,
      "documents" => documents_values,
      "eaf" => eaf_values,
      "flextext" => flextext_values,
      "images" => images_values,
      "ixt" => ixt_values,
      "trs" => trs_values,
      "video" => video_values
    }
    respond_to do |format|
      format.json do
        render json: response_value
      end
    end
  end

  def create
    @item.assign_attributes(params[:item].except(:item_agents_attributes))

    if @item.save
      # update xml file of the item
      save_item_catalog_file(@item)

      flash[:notice] = 'Item was successfully created.'
      redirect_to [@collection, @item]
    else
      @page_title = 'Nabu - Add New Item'
      render :action => 'new'
    end
  end

  def edit
    @page_title = 'Nabu - Edit Item'
  end

  def destroy
    response = ItemDestructionService.new(@item, params[:delete_essences]).destroy

    flash[:notice] = response[:messages][:notice]
    flash[:error] = response[:messages][:error]

    if response[:success]
      unless params[:delete_essences]
        undo_link = view_context.link_to("undo", revert_version_path(@item.versions.last), :method => :post, :class => 'undo')
        flash[:notice] = flash[:notice] + " (#{undo_link})"
      end
      redirect_to @collection
    else
      redirect_to [@collection, @item]
    end
  end

  def inherit_details
    if @item.inherit_details_from_collection(params[:override_existing])
      flash[:notice] = 'Successfully inherited attributes from collection'
    else
      flash[:alert] = 'Failed to inherit attributes from collection'
    end

    redirect_to [@collection, @item]
  end

  def update
    if params[:item] && params[:item][:user_ids].is_a?(String) && !params[:item][:user_ids].empty?
      flash[:alert] = "Error in submitted value for View/Download access users"
      redirect_to [@collection, @item]
      return
    end
    Rails.logger.info "Start of ItemsController#update for #{@collection.identifier}-#{@item.identifier}"
    @num_files = @item.essences.length
    @files = @item.essences.page(params[:files_page]).per(params[:files_per_page])

    if @item.update_attributes(params[:item])
      # update xml file of the item
      save_item_catalog_file(@item)

      flash[:notice] = 'Item was successfully updated.'
      redirect_to [@collection, @item]
    else
      @page_title = 'Nabu - Edit Item'
      render :action => "edit"
    end
    Rails.logger.info "End of ItemsController#update for #{@collection.identifier}-#{@item.identifier}"
  end

  def bulk_edit
    @item = Item.new
    @item.collection = Collection.new
    @page_title = 'Nabu - Items Bulk Update'

    build_advanced_search(params)
    build_deletable_params(@item, @items)
  end


  def bulk_update
    accessible_items = Item.accessible_by(current_ability)
                           .where(id: params[:item_ids].split(' '))
                           .pluck(:id)
    BulkUpdateItemsService.new(item_ids: accessible_items,
                               current_user_email: current_user.try(:email),
                               updates: params[:item]).delay.update_items

    flash[:notice] = "Items will be updated shortly, you'll be notified once it's completed"
    redirect_to bulk_update_items_path + "?#{params[:original_search_params]}"
  end

  def display
    send_file @item.path, :disposition => 'inline', :type => 'text/xml'
  end

  def new_report
    @page_title = 'Nabu - Depositor Item Report Request'
  end

  def report_sent
    @page_title = 'Nabu - Depositor Item Report Request'
  end

  def send_report
    @date_from = params["date_from"]
    @date_to = params["date_to"]

    downloads_report_service = DownloadsReportService.new(@date_from, @date_to, current_user)

    @send_result = downloads_report_service.send_report

    redirect_to report_sent_items_path, flash: { send_result: @send_result }
  end

  private

  def tidy_params
    if params[:item]
      params[:item][:item_agents_attributes] ||= {}
      params[:item][:item_agents_attributes].each_pair do |_id, iaa|
        name = iaa['user_id']
        if name =~ /^NEWCONTACT:/
          iaa['user_id'] = create_contact(name)
        end
      end
      if params[:item][:collector_id] =~ /^NEWCONTACT:/
        params[:item][:collector_id] = create_contact(params[:item][:collector_id])
      end

      if params[:existing_id].present?
        agent_attrs = params[:item].delete(:item_agents_attributes)
        new_agents = agent_attrs.select {|_k, v| v[:id].nil? }
        agent_ids = agent_attrs.reject {|_k, v| v[:id].nil? || v['_destroy'].to_s != '0' }.map {|_k, v| v['id'] }

        params[:item][:item_agents_attributes] = {}
        i = 0
        ItemAgent.where(id: agent_ids).each do |x|
          params[:item][:item_agents_attributes][i.to_s] = {user_id: x.user_id, agent_role_id: x.agent_role_id}
          i += 1
        end

        new_agents.each do |_k, v|
          params[:item][:item_agents_attributes][i.to_s] = {user_id: v['user_id'].to_i, agent_role_id: v['agent_role_id'].to_i}
          i += 1
        end
      end
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
    return if item.nil?
    ItemCatalogService.new(item).delay.save_file
  end

  def stream_csv(search_type)
    downloader = CsvDownloader.new(search_type, params, current_user)
    export_all = params[:export_all] || false
    per_page = (params[:per_page] || 10).to_i
    
    # only stream CSV if small enough
    if @search.total <= 5000 || (!export_all && per_page <= 5000)
      filename, body = downloader.stream(@search)
      
      self.response.headers['Content-Type'] = 'text/csv; charset=utf-8; header=present'
      self.response.headers['Content-Disposition'] = "attachment; filename=#{filename}"
      self.response.headers['Last-Modified'] = Time.now.ctime.to_s

      self.response_body = Enumerator.new &body
      return
    end
    
    # otherwise use delayed_job to email a CSV
    
    downloader.delay.email
    
    flash[:notice] = 'Your CSV file was too large to download directly. It will be generated and sent to you via email.'
    redirect_to :back
  end

  def build_advanced_search(params)
    @types_for_fields = ItemQueryBuilder::TYPES_FOR_FIELDS
    @fields = @types_for_fields.keys.map(&:to_s).sort

    if params[:clause].present?
      @search = build_query(params)
      @items = @search
      session[:result_ids] = @search.map(&:full_identifier)
    else
      @search = ItemSearchService.build_advanced_search(params, current_user)
      @items = @search.hits.map(&:result)
      session[:result_ids] = @search.hits.map{|h|h.stored(:full_identifier)}
    end
  end

  def build_deletable_params(item, items)
    item.bulk_deleteable[:countries] = bulk_deletable_relation(ItemCountry, Country, :country_id, items)
    item.bulk_deleteable[:subject_languages] = bulk_deletable_relation(ItemSubjectLanguage, Language, :language_id, items)
    item.bulk_deleteable[:content_languages] = bulk_deletable_relation(ItemContentLanguage, Language, :language_id, items)
    item.bulk_deleteable[:data_categories] = bulk_deletable_relation(ItemDataCategory, DataCategory, :data_category_id, items)
    item.bulk_deleteable[:data_types] = bulk_deletable_relation(ItemDataType, DataType, :data_type_id, items)
  end

  def bulk_deletable_relation(relation, associated_resource, associated_resource_id, items)
    ids = relation.where(item_id: items.map(&:id))
            .group_by(&associated_resource_id)
            .keys
    associated_resource.where(id: ids).map do |resource|
      { id: resource.id, text: resource.name }
    end if ids.present?
  end
end
