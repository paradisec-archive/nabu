class RepositoryController < ApplicationController

  def collection
    collection = Collection.find_by_identifier params[:collection_identifier]
    redirect_to collection
  end

  def item
    if params[:full_identifier]
      params[:collection_identifier], params[:item_identifier] = params[:full_identifier].split(/-/)
    end
    collection = Collection.find_by_identifier params[:collection_identifier]
    item = collection.items.find_by_identifier params[:item_identifier]
    redirect_to [collection, item]
  end

  def essence
    collection = Collection.find_by_identifier params[:collection_identifier]
    item = collection.items.find_by_identifier params[:item_identifier]
    essence = item.essences.find params[:essence_id]
    redirect_to [collection, item, essence]
  end

end
