class ItemsController < ApplicationController
  before_action :find_item, only: %i[show edit]
  load_and_authorize_resource :collection, find_by: :identifier,
                                           except: %i[search advanced_search bulk_update bulk_edit new_report send_report report_sent]
  load_and_authorize_resource :item, find_by: :identifier, through: :collection,
                                     except: %i[search advanced_search bulk_update bulk_edit new_report send_report report_sent]
  authorize_resource only: %i[advanced_search bulk_update bulk_edit new_report send_report report_sent]

  include HasReturnToLastSearch
  include HasSearch
  self.search_model = Item

  def show
    @page_title = "Nabu - #{@item.title}"
    @num_files = @item.essences.length
    @files = @item.essences.page(params[:files_page]).per(params[:files_per_page])

    @files = @files.order(params[:sort] ? "#{params[:sort]} #{params[:direction]}" : :filename)
  end

  def new
    @page_title = 'Nabu - Add New Item'

    return unless params[:id]

    # For creating duplicate items
    existing = Item.find(params[:id])
    attributes = existing.attributes.select do |attr, _value|
      Item.column_names.include?(attr.to_s)
    end

    attributes.delete('id')

    associations = %i[country_ids subject_language_ids content_language_ids admin_ids user_ids data_category_ids data_type_ids]
    associations.each do |association|
      attributes[association] = existing.public_send(association)
    end

    @item = Item.new(attributes)
    @item.item_agents = []
    existing.item_agents.each do |a|
      @item.item_agents << ItemAgent.new(user_id: a.user_id, agent_role_id: a.agent_role_id)
    end
  end

  def edit
    @page_title = 'Nabu - Edit Item'
  end

  def create
    if @item.save
      flash[:notice] = 'Item was successfully created.'

      redirect_to [@collection, @item]
    else
      @page_title = 'Nabu - Add New Item'

      render action: 'new'
    end
  end

  def update
    if params[:item] && params[:item][:user_ids].is_a?(String) && !params[:item][:user_ids].empty?
      flash[:alert] = 'Error in submitted value for View/Download access users'
      redirect_to [@collection, @item]
      return
    end

    @num_files = @item.essences.length
    @files = @item.essences.page(params[:files_page]).per(params[:files_per_page])

    if @item.update(item_params)
      flash[:notice] = 'Item was successfully updated.'
      redirect_to [@collection, @item]
    else
      @page_title = 'Nabu - Edit Item'
      render action: 'edit'
    end
  end

  def destroy
    response = ItemDestructionService.destroy(@item)

    flash[:notice] = response[:messages][:notice]
    flash[:error] = response[:messages][:error]

    if response[:success]
      if response[:can_undo]
        undo_link = view_context.link_to('undo', revert_version_path(@item.versions.last), method: :post, class: 'undo')
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

  def search
    return if try_full_identifier_redirect

    @page_title = 'Nabu - Item Search'
    @params = basic_search_params
    @search = build_basic_search

    @result_ids = @search.map(&:full_identifier) if params[:search]

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
    search_params = params[:export_all] ? advanced_search_params.merge(per_page: 10_000, start_page: 1) : advanced_search_params

    @page_title = 'Nabu - Advanced Item Search'
    @params = search_params

    build_advanced_search

    @search = build_advanced_search

    @result_ids = @search.map(&:full_identifier)

    respond_to do |format|
      format.html
      if can? :search_csv, Item
        format.csv do
          stream_csv(:advanced)
        end
      end
    end
  end

  def bulk_edit
    @item = Item.new
    @item.collection = Collection.new
    @page_title = 'Nabu - Items Bulk Update'
    @params = advanced_search_params

    @items = build_advanced_search
    build_deletable_params(@item, @items)
  end

  def bulk_update
    @params = advanced_search_params

    accessible_items = Item.accessible_by(current_ability)
                           .where(id: params[:item_ids].split)
                           .pluck(:id)
    BulkUpdateItemsJob.perform_later(item_ids: accessible_items,
                               current_user_email: current_user.try(:email),
                               updates: item_params)

    flash[:notice] = "Items will be updated shortly, you'll be notified once it's completed"
    redirect_to bulk_update_items_path + "?#{params[:original_search_params]}"
  end

  def private_rocrate
    @data = @item
    @admin_rocrate = true

    json_data = render_to_string(template: 'api/v1/oni/object_meta_item', formats: [:json], handlers: [:jb])
    send_data json_data, filename: "#{@item.full_identifier}-ro-crate-metadata.json", type: 'application/json', disposition: 'attachment'
  end

  def public_rocrate
    @data = @item
    @admin_rocrate = false

    json_data = render_to_string(template: 'api/v1/oni/object_meta_item', formats: [:json], handlers: [:jb])
    send_data json_data, filename: "#{@item.full_identifier}-ro-crate-metadata.json", type: 'application/json', disposition: 'attachment'
  end

  def new_report
    @page_title = 'Nabu - Depositor Item Report Request'
  end

  def report_sent
    @page_title = 'Nabu - Depositor Item Report Request'
  end

  def send_report
    @date_from = params['date_from']
    @date_to = params['date_to']

    downloads_report_service = DownloadsReportService.new(@date_from, @date_to, current_user)

    @send_result = downloads_report_service.send_report

    redirect_to report_sent_items_path, flash: { send_result: @send_result }
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
      essence_extension = File.extname(essence_filename)[1..]
      essence_basename = File.basename(essence_filename, ".#{essence_extension}")
      repository_essence_url = repository_essence_url(@collection, @item, essence.filename)

      case essence_extension
      when 'eaf'
        eaf_values[essence_basename] ||= []
        eaf_values[essence_basename] << repository_essence_url
      when 'flextext'
        flextext_values[essence_basename] ||= []
        flextext_values[essence_basename] << repository_essence_url
      when 'ixt'
        ixt_values[essence_basename] ||= []
        ixt_values[essence_basename] << repository_essence_url
      when 'trs'
        trs_values[essence_basename] ||= []
        trs_values[essence_basename] << repository_essence_url
        # ASSUMPTION: webm is a video, not an audio, based on email from Nick Thien.
        # ENHANCEMENT: Using essence.mimetype would be more robust.
        # when "mp3", "webm", "ogg", "oga"
      when 'mp3', 'ogg', 'oga'
        unless audio_values.key?(essence_basename)
          audio_values[essence_basename] = {
            'files' => []
          }
        end
        audio_values[essence_basename]['files'] << repository_essence_url
      when 'mp4', 'webm', 'ogv', 'mov'
        video_values[essence_basename] ||= []
        video_values[essence_basename] << repository_essence_url
      when 'jpg', 'jpeg', 'png'
        # REQUIREMENTS: There are scenarios where multiple originals have the same essence basename. Is that ok as far as the player is concerned?
        unless images_values.key?(essence_basename)
          images_values[essence_basename] = {
            'originals' => []
          }
        end
        images_values[essence_basename]['originals'] << repository_essence_url
      when 'pdf'
        documents_values << repository_essence_url
      end
    end

    response_value = {
      'audio' => audio_values,
      'documents' => documents_values,
      'eaf' => eaf_values,
      'flextext' => flextext_values,
      'images' => images_values,
      'ixt' => ixt_values,
      'trs' => trs_values,
      'video' => video_values
    }
    # Ignore the file
    respond_to do |format|
      format.json do
        render json: response_value
      end
    end
  end

  private

  def try_full_identifier_redirect
    return if params[:search].blank?

    collection_identifier, item_identifier = params[:search].split('-')

    return unless collection_identifier.present? && item_identifier.present?

    collection = Collection.find_by(identifier: collection_identifier)

    return unless collection

    item = collection.items.find_by(identifier: item_identifier)

    return unless item

    redirect_to [collection, item]

    true
  end

  def tidy_params!
    options = params[:item]

    return unless options

    options[:item_agents_attributes] ||= {}
    options[:item_agents_attributes].each_pair do |_id, iaa|
      name = iaa['user_id']
      iaa['user_id'] = create_contact(name) if name =~ /^NEWCONTACT:/
    end

    options[:collector_id] = create_contact(options[:collector_id]) if options[:collector_id] =~ /^NEWCONTACT:/
  end

  def find_by_full_identifier
    if params[:id]
      collection_identifier, item_identifier = params[:id].split('-')
      @collection = Collection.find_by(identifier: collection_identifier)
      @item = @collection.items.find_by(identifier: item_identifier)
    elsif params[:collection_id]
      @collection = Collection.find_by(identifier: params[:collection_id])
    end
  end

  # So we can include things and solve N + 1 queries
  def find_item
    @collection = Collection.find_by!(identifier: params[:collection_id])
    @item = @collection.items
                       .includes([
                                   { item_agents: %i[agent_role user] },
                                   :data_types,
                                   :data_categories,
                                   :admins,
                                   :users,
                                   :collection,
                                   :essences,
                                   :countries,
                                   :subject_languages,
                                   :content_languages
                                 ])
                       .find_by!(identifier: params[:id])
  end

  def stream_csv(search_type)
    export_all = params[:export_all] || false
    downloader = CsvDownloaderService.new(search_type, @params, current_user)

    # TODO: fix CSV stream for builder method

    filename, body = downloader.stream(@search)

    headers['Content-Type'] = 'text/csv; charset=utf-8; header=present'
    headers['Content-Disposition'] = "attachment; filename=#{filename}"
    headers['Last-Modified'] = Time.now.httpdate

    response.status = 200

    self.response_body = Enumerator.new(&body)
  end

  def build_deletable_params(item, items)
    item.bulk_deleteable[:countries] = bulk_deletable_relation(ItemCountry, Country, :country_id, items)
    item.bulk_deleteable[:subject_languages] =
      bulk_deletable_relation(ItemSubjectLanguage, Language, :language_id, items)
    item.bulk_deleteable[:content_languages] =
      bulk_deletable_relation(ItemContentLanguage, Language, :language_id, items)
    item.bulk_deleteable[:data_categories] =
      bulk_deletable_relation(ItemDataCategory, DataCategory, :data_category_id, items)
    item.bulk_deleteable[:data_types] = bulk_deletable_relation(ItemDataType, DataType, :data_type_id, items)
  end

  def bulk_deletable_relation(relation, associated_resource, associated_resource_id, items)
    ids = relation.where(item_id: items.map(&:id))
                  .group_by(&associated_resource_id)
                  .keys

    return if ids.blank?

    associated_resource.where(id: ids).map do |resource|
      { id: resource.id, text: resource.name }
    end
  end

  def basic_search_params
    params.permit(
      :format,
      :search, :page, :per_page, :sort, :direction,
      :countries, :content_languages, :collector_name,
      :export_all
    )
  end

  def advanced_search_params
    # FIXME: Is this bad?
    params.except(:controller, :action, :utf8).permit!
  end

  def item_params
    tidy_params! if %w[create update bulk_update].include?(params[:action])

    params
      .require(:item)
      .permit(
        :identifier, :title, :external, :url, :description, :region, :collection_id,
        :north_limit, :south_limit, :west_limit, :east_limit,
        :collector_id, :university_id, :operator_id,
        :country_ids, :data_category_ids, :data_type_ids,
        :content_language_ids, :subject_language_ids,
        :admin_ids, :agent_ids, :user_ids,
        :access_condition_id,
        :access_narrative, :private,
        :admin_comment,
        :originated_on, :originated_on_narrative, :language,
        :dialect, :discourse_type_id,
        :metadata_exportable, :born_digital, :tapes_returned,
        :original_media, :ingest_notes, :tracking,
        :received_on, :digitised_on, :metadata_imported_on, :metadata_exported_on,
        :bulk_edit_append_title, :bulk_edit_append_description, :bulk_edit_append_region,
        :bulk_edit_append_originated_on_narrative, :bulk_edit_append_url, :bulk_edit_append_language,
        :bulk_edit_append_dialect, :bulk_edit_append_original_media, :bulk_edit_append_ingest_notes,
        :bulk_edit_append_tracking, :bulk_edit_append_access_narrative, :bulk_edit_append_admin_comment,
        :bulk_edit_append_country_ids, :bulk_edit_append_subject_language_ids, :bulk_edit_append_content_language_ids,
        :bulk_edit_append_admin_ids, :bulk_edit_append_user_ids, :bulk_edit_append_data_category_ids, :bulk_edit_append_data_type_ids,
        :bulk_delete_country_ids, :bulk_delete_subject_language_ids,
        :bulk_delete_content_language_ids, :bulk_delete_data_category_ids, :bulk_delete_data_type_ids,

        item_agents_attributes: {},
        country_ids: [], subject_language_ids: [], content_language_ids: [], data_category_ids: [], data_type_ids: [], admin_ids: [], user_ids: []
      )
  end
end
