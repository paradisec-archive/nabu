class RepositoryController < ApplicationController

  def collection
    collection = Collection.find_by_identifier params[:collection_identifier]
    redirect_to collection
  end

  def item
    collection = Collection.find_by_identifier params[:collection_identifier]
    item = collection.items.find_by_identifier params[:item_identifier]
    redirect_to item
  end

  def essence
    collection = Collection.find_by_identifier params[:collection_identifier]
    item = collection.items.find_by_identifier params[:item_identifier]
    essence = item.essences.find_by_file_name params[:essence_identifier]
    redirect_to essence
  end

end
