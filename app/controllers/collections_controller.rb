class CollectionsController < ApplicationController
  load_and_authorize_resource

  def index
    @collections = @collections.order 'collections.' + sort_column + ' ' + sort_direction
    if params[:clear]
      params.delete(:search)
      redirect_to collections_path
    end

    if params[:search]
      match = "%#{params[:search]}%"
      @collections = @collections.where{ (title =~ match) | (description =~ match) | (identifier =~ match) }
    end

    @collections = @collections.page(params[:page]).per(params[:per_page])
  end

  def new
    build_associations
  end

  def show
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
    build_associations
  end

  def update
    if @collection.update_attributes(params[:collection])
      flash[:notice] = 'Collection was successfully updated.'
      redirect_to @collection
    else
      render :action => "edit"
    end
  end

  private
  def build_associations
    @collection.collection_languages.build
    @collection.collection_countries.build
    @collection.collection_admins.build
  end

end
