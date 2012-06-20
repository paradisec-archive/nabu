class RepositoryController < ApplicationController

  def redirect
    collection = Collection.find_by_identifier params[:collection_identifier]
    item = collection.items.find_by_identifier params[:item_identifier]
    redirect_to item
  end

end