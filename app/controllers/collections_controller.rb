require 'nabu/ex_site9'
require 'nabu/nabu_spreadsheet'

# rubocop:disable Metrics/ClassLength
class CollectionsController < ApplicationController
  include HasReturnToLastSearch

  before_action :tidy_params, only: %i[create update bulk_update]
  load_and_authorize_resource find_by: :identifier, except: %i[search advanced_search bulk_update bulk_edit]
  authorize_resource only: %i[advanced_search bulk_update bulk_edit]

  def index
    @collections = Collection.where(private: false)

    respond_to do |format|
      format.geo_json do
        json = {
          type: 'FeatureCollection',
          metadata: {
            id: 'PARADISEC',
            name: 'PARADISEC Collections',
            description: 'PARADISEC (Pacific And Regional Archive for DIgital Sources in Endangered Cultures) curates digital material about small or endangered languages.',
            url: 'https://catalog.paradisec.org.au',
            public: true,
            publisher: 'Pacific and Regional Archive for Digital Sources in Endangered Cultures (PARADISEC)',
            contact: 'admin@paradisec.org.au',
          },
          display: {
            basemapGallery: false,
            info: {
              display: 'disabled'
            }
          },
          features: @collections.map { |collection| collection.as_geo_json(repository_collection_url(collection)) }.compact
        }

        render json:
      end
    end
  end

  def show
    @num_items = @collection.items.count
    @num_items_ready = @collection.items.where.not(digitised_on: nil).count
    @num_essences = Essence.where(item_id: @collection.items).count

    @items = @collection.items.includes(:access_condition, :collection).page(params[:items_page]).per(params[:items_per_page])

    @items = @items.order(params[:sort] ? "#{params[:sort]} #{params[:direction]}" : :identifier)

    @page_title = "Nabu - #{@collection.title}"

    license = @collection.access_condition.name if @collection.access_condition
    rights = @collection.access_condition.name if @collection.access_condition

    respond_to do |format|
      format.geo_json do
        json = {
          type: 'FeatureCollection',
          metadata: {
            id: @collection.full_identifier,
            name: @collection.title,
            description: @collection.description || '',
            url: repository_collection_url(@collection),
            public: true,
            publisher: @collection.collector.name,
            contact: 'admin@paradisec.org.au',
            license:,
            rights:
          },
          display: {
            basemapGallery: false,
            info: {
              display: 'disabled',
            }
          },
          features: @collection.items.map { |item| item.as_geo_json(repository_item_url(@collection, item)) }.compact
        }

        render json:
      end
      format.html
      format.xml
    end
  end

  def new
    @page_title = 'Nabu - Add New Collection'
  end

  def edit
    @page_title = 'Nabu - Edit Collection'
    @num_items = @collection.items.count

    @items = @collection.items.includes(:access_condition, :collection).order(:identifier).page(params[:items_page]).per(params[:items_per_page])
  end

  def create
    # Make the depositor an admin
    @collection.admins << current_user unless @collection.admins.include? current_user

    if @collection.save
      flash[:notice] = 'Collection was successfully created.'

      redirect_to @collection
    else
      @page_title = 'Nabu - Add New Collection'

      render action: 'new'
    end
  end

  def update
    if @collection.update(collection_params)
      flash[:notice] = 'Collection was successfully updated.'
      redirect_to @collection
    else
      @num_items = @collection.items.count

      @items = @collection.items.order(:identifier).page(params[:items_page]).per(params[:items_per_page])
      @page_title = 'Nabu - Edit Collection'

      render action: 'edit'
    end
  end

  def destroy
    response = CollectionDestructionService.destroy(@collection)

    flash[:notice] = response[:messages][:notice]
    flash[:error] = response[:messages][:error]

    if response[:success]
      if response[:can_undo]
        undo_link = view_context.link_to('undo', revert_version_path(@collection.versions.last), method: :post, class: 'undo')
        flash[:notice] = flash[:notice] + " (#{undo_link})"
      end
      redirect_to search_collections_path
    else
      redirect_to @collection
    end
  end

  def search
    params.delete(:per_page) if params[:per_page] == '0'

    @page_title = 'Nabu - Collections'
    @params = search_params

    @search = Collection.solr_search(include: %i[collector countries languages university]) do
      fulltext params[:search]
      facet :language_ids, :country_ids
      facet :collector_id, limit: 100

      with(:language_codes, params[:language_code]) if params[:language_code].present?
      with(:country_codes, params[:country_code]) if params[:country_code].present?
      with(:collector_id, params[:collector_id]) if params[:collector_id].present?

      unless current_user&.admin?
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
      paginate page: params[:page], per_page: params[:per_page]
    end

    if params[:page].to_i > 1 && params[:page].to_i > @search.results.total_pages
      redirect_to search_collections_path(search_params.merge(page: 1))
      return
    end

    respond_to do |format|
      format.html
      if can? :search_csv, Collection
        # This uses attributes that an HTML request doesn't use. Some attributes here ought to be eagerly loaded but aren't.
        format.csv do
          response.headers['Content-Type'] = 'text/csv'
          response.headers['Content-Disposition'] = 'attachment; filename=search.csv'
        end
      end
    end
  end

  def advanced_search
    params.delete(:per_page) if params[:per_page] == '0'

    @page_title = 'Nabu - Advanced Search Collections'
    @params = advanced_search_params

    @search = build_advanced_search

    respond_to do |format|
      format.html
      if can? :search_csv, Collection
        # This uses attributes that an HTML request doesn't use. Some attributes here ought to be eagerly loaded but aren't.
        format.csv do
          response.headers['Content-Type'] = 'text/csv'
          response.headers['Content-Disposition'] = 'attachment; filename=search.csv'
          render template: 'collections/search'
        end
      end
    end
  end

  def bulk_edit
    @page_title = 'Nabu - Collections Bulk Update'
    @params = advanced_search_params
    @collection = Collection.new

    @search = build_advanced_search
  end

  def bulk_update
    @collections = Collection.accessible_by(current_ability).where(id: params[:collection_ids].split)

    data = collection_params.to_h
    data.compact_blank!

    # Collect the fields we are appending to
    appendable = {}
    data.each_pair do |k, v|
      next unless k =~ /^bulk_edit_append_(.*)/

      sub_field = ::Regexp.last_match(1)
      appendable[sub_field] = data.delete sub_field if v == '1'
      data.delete k
    end

    invalid_record = false
    @collections.each do |collection|
      appendable.each_pair do |k, v|
        if collection.public_send(k).nil?
          data[k.to_sym] = v if v.present?
        elsif v.present?
          data[k.to_sym] = collection.public_send(k)
        end
      end

      next if collection.update(data)

      invalid_record = true
      @collection = collection
      break
    end

    appendable.each_pair do |k, v|
      data[k.to_sym] = nil
      data["bulk_edit_append_#{k}"] = v
    end

    if invalid_record
      @page_title = 'Nabu - Collections Bulk Update'
      @collection = Collection.new
      @search = build_advanced_search
      render action: 'bulk_edit'
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
      @collection ||= Collection.new
      flash.now[:error] = 'No ExSite9 file submitted'
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
      flash[:notice] ||= 'SUCCESS: Collection created'
      flash[:notice] += exsite9.notices.join('<br/>') if exsite9.notices.present?
      redirect_to @collection
    else
      @collection ||= Collection.new
      flash.now[:notice] = exsite9.notices.join('<br/>') if exsite9.notices.present?
      flash.now[:error] = exsite9.errors.join('<br/>') if exsite9.errors.present?
      render 'new_from_metadata'
    end
  end

  def create_from_spreadsheet
    unless params.key?(:collection)
      @collection ||= Collection.new
      flash.now[:error] = 'No Spreadsheet XLS file submitted'
      render 'new_from_metadata'
      return
    end

    # get XSL data
    data = params[:collection][:metadata].read
    # parse XML file as Spreadsheet
    sheet = Nabu::NabuSpreadsheet.new_of_correct_type(data)
    sheet.parse

    if sheet.valid?
      @collection = sheet.collection
      @collection.save!
      saved_items = 0
      added_items = ''
      sheet.items.each do |item|
        item.save!
        saved_items += 1
        added_items += "#{item.identifier}, "
      end
      flash[:notice] = "SUCCESS: #{saved_items} items created/updated for collection #{@collection.identifier}<br/>"
      flash[:notice] += sheet.notices.join('<br/>').truncate(500) unless sheet.notices.empty?
      flash[:notice] += "<br/>Added items: #{added_items.chomp(', ')}".truncate(500)
      flash[:notice] += ' Truncated...'

      redirect_to @collection
    else
      @collection ||= Collection.new
      flash.now[:notice] = sheet.notices.join('<br/>').truncate(500) unless sheet.notices.empty?
      flash.now[:error] = sheet.errors.join('<br/>').truncate(500) unless sheet.errors.empty?
      render 'new_from_metadata'
    end
  end

  private

  def tidy_params
    return unless params[:collection]

    # this is used to allow grants where there is a funding body but no grant id
    if params[:collection][:grants_attributes]
      # map the collection identifier to the underlying id
      collection_id = Collection.where(identifier: params[:id]).pick(:id)
      grants = params[:collection][:grants_attributes]

      funding_body_ids = params['funding_body_ids'] || []

      fbids = funding_body_ids.reject { |x| grants.pluck(:funding_body_id).include?(x) }

      # for each funding body that doesn't have grant ids, create an empty grant

      params[:collection][:grants_attributes].concat(fbids.collect { |x| { 'funding_body_id' => x, 'grant_identifier' => nil } })
      # apply the current collection to every item
      params[:collection][:grants_attributes].each { |g| g['collection_id'] = collection_id }
    end

    params[:collection][:collector_id] = create_contact(params[:collection][:collector_id]) if params[:collection][:collector_id] =~ /^NEWCONTACT:/
  end

  def build_advanced_search
    Collection.solr_search(include: %i[collector countries languages university]) do
      # Full text search
      Sunspot::Setup.for(Collection).all_text_fields.each do |field|
        next if params[field.name].blank?

        keywords params[field.name], fields: [field.name]
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
          with(field.name).between(Time.parse(params[field.name]).beginning_of_day)..(Time.parse(params[field.name]).end_of_day)
        else
          logger.warn "WARNING can't search: #{field.type} #{field.name}"
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

      unless current_user&.admin?
        any_of do
          with(:private, false)
          with(:admin_ids, current_user.id) if current_user
        end
      end

      sort_column(Collection).each do |c|
        order_by c, sort_direction
      end

      paginate page: params[:page], per_page: params[:per_page]
    end
  end

  def search_params
    params.permit(
      :search, :page, :per_page, :sort, :direction,
      :language_code, :country_code, :collector_id
    )
  end

  def advanced_search_params
    # FIXME: Is this bad?
    params.except(:controller, :action, :utf8).permit!
  end

  def collection_params
    params
      .require(:collection)
      .permit(
        :identifier, :title, :description, :region,
        :north_limit, :south_limit, :west_limit, :east_limit,
        :collector_id, :operator_id, :university_id, :field_of_research_id,
        :grants_attributes,
        :access_condition_id,
        :bulk_edit_append_title, :bulk_edit_append_description, :bulk_edit_append_region,
        :bulk_edit_append_access_narrative, :bulk_edit_append_metadata_source,
        :bulk_edit_append_orthographic_notes, :bulk_edit_append_media, :bulk_edit_append_comments,
        :bulk_edit_append_tape_location, # :bulk_edit_append_grant_identifier,
        :bulk_edit_append_country_ids, :bulk_edit_append_language_ids, :bulk_edit_append_admin_ids,

        :complete, :private, :access_narrative, :metadata_source, :orthographic_notes, :media, :comments,
        :deposit_form_received, :tape_location,

        language_ids: [], country_ids: [], admin_ids: []
      )
  end
end
# rubocop:enable Metrics/ClassLength
