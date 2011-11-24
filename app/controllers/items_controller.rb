class ItemsController < ApplicationController
  load_and_authorize_resource :collection
  load_and_authorize_resource :item, :through => :collection, :shallow => true

  def index
    @items = @items.order sort_column + ' ' + sort_direction
    if params[:clear]
      params.delete(:search)
      redirect_to items_path
    end

    if params[:search]
      match = "%#{params[:search]}%"
      @items = @items.where{ (title =~ match) | (description =~ match) | (identifier =~ match) }
    end

    @items = @items.page(params[:page]).per(params[:per_page])
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
    @item.item_admins.build
  end

end
