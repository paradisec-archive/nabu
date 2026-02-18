require 'ostruct'

class RepositoryController < ApplicationController
  def collection
    collection = Collection.find_by(identifier: params[:collection_identifier])

    raise ActionController::RoutingError, "Collection not found: #{params[:collection_identifier]}" if collection.nil?

    if params[:edit].present?
      redirect_to edit_collection_path(collection), status: :moved_permanently
    else
      redirect_to helpers.oni_collection_url(collection), status: :moved_permanently, allow_other_host: true
    end
  end

  def item
    params[:collection_identifier], params[:item_identifier] = params[:full_identifier].split('-') if params[:full_identifier]

    collection = Collection.find_by(identifier: params[:collection_identifier])
    raise ActionController::RoutingError, "Collection not found: #{params[:collection_identifier]}" if collection.nil?

    item = collection.items.find_by(identifier: params[:item_identifier])
    raise ActionController::RoutingError, "Item not found: #{params[:collection_identifier]}-#{params[:collection_identifier]}" if item.nil?

    if params[:edit].present?
      redirect_to edit_collection_item_path(collection, item), status: :moved_permanently
    else
      redirect_to helpers.oni_item_url(item), status: :moved_permanently, allow_other_host: true
    end
  end

  def essence
    collection = Collection.find_by(identifier: params[:collection_identifier])
    raise ActionController::RoutingError, "Collection not found: #{params[:collection_identifier]}" if collection.nil?

    item = collection.items.find_by(identifier: params[:item_identifier])
    raise ActionController::RoutingError, "Item not found: #{params[:collection_identifier]}-#{params[:collection_identifier]}" if item.nil?

    essence = item.essences.find_by(filename: params[:essence_filename])
    raise ActionController::RoutingError, "Essence not found: #{params[:essence_filename]}" if essence.nil?

    authorize! :read, essence

    location = Nabu::Catalog.instance.essence_url(essence, as_attachment: true)
    raise ActionController::RoutingError, 'Essence file not found' unless location

    redirect_to location, allow_other_host: true
  end
end
