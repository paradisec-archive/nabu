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
      facet :content_language_ids, :country_ids, :university_id

      with(:university_id, params[:university_id]) if params[:university_id].present?
      with(:content_language_ids, params[:content_language_id]) if params[:language_id].present?
      with(:country_ids, params[:country_id]) if params[:country_id].present?

      with(:private, false) unless current_user.admin?
      order_by sort_column, sort_direction
      paginate :page => params[:page], :per_page => params[:per_page]
    end
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

  private
  def build_associations
    @item.item_countries.build
    @item.item_subject_languages.build
    @item.item_content_languages.build
    @item.item_admins.build
    @item.item_agents.build
  end

end
