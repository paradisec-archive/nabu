require 'ostruct'
require 'nabu/media'

class RepositoryController < ApplicationController
  def collection
    collection = Collection.find_by(identifier: params[:collection_identifier])

    raise ActionController::RoutingError, "Collection not found: #{params[:collection_identifier]}" if collection.nil?

    redirect_to collection, status: :moved_permanently
  end

  def item
    params[:collection_identifier], params[:item_identifier] = params[:full_identifier].split('-') if params[:full_identifier]

    collection = Collection.find_by(identifier: params[:collection_identifier])
    raise ActionController::RoutingError, "Collection not found: #{params[:collection_identifier]}" if collection.nil?

    item = collection.items.find_by(identifier: params[:item_identifier])
    raise ActionController::RoutingError, "Item not found: #{params[:collection_identifier]}-#{params[:collection_identifier]}" if item.nil?

    redirect_to [collection, item], status: :moved_permanently
  end

  def essence
    collection = Collection.find_by(identifier: params[:collection_identifier])
    raise ActionController::RoutingError, "Collection not found: #{params[:collection_identifier]}" if collection.nil?

    item = collection.items.find_by(identifier: params[:item_identifier])
    raise ActionController::RoutingError, "Item not found: #{params[:collection_identifier]}-#{params[:collection_identifier]}" if item.nil?

    essence = item.essences.find_by(filename: params[:essence_filename])
    raise ActionController::RoutingError, "Essence not found: #{params[:essence_filename]}" if essence.nil?

    # if a standard essence file was found, return that as usual
    if essence.present?
      authorize! :read, essence
      location = Proxyist.get_object(essence.item.full_identifier, essence.filename, download: true)
      raise ActionController::RoutingError, 'Essence file not found' unless location

      redirect_to location, allow_other_host: true

      return
    elsif params[:essence_filename].include?('PDSC_ADMIN') # otherwise look up to see if there is a hidden admin file (thumbnails, soundimage file, etc.)
      location = admin_essence_location(collection, item, params[:essence_filename])
      raise ActionController::RoutingError, 'Essence file not found' unless location

      redirect_to location, allow_other_host: true if location

      return
    end

    raise ActionController::RoutingError, "Repository file not found: #{params[:essence_filename]}"
  end

  private

  # this expects any admin-style files to have a name of the form "<essence identifier part>-<type>-PDSC_ADMIN.<extension>"
  # e.g. AA1-001-essence-file-goes-here-thumb-PDSC_ADMIN.jpg where collection AA1 has item 001 with essence "essence-file-goes-here"
  def admin_essence_location(collection, item, essence_filename)
    item_prefix = "#{collection.identifier}-#{item.identifier}-"
    essence_part = essence_filename.sub(item_prefix, '').sub(/^(.+?)-[^-]+?-PDSC_ADMIN\..+/, '\1')
    essence = item.essences.where('filename LIKE :prefix', prefix: "#{item_prefix}#{essence_part}%").first

    # don't allow the user to randomly access data, must relate directly to an essence file
    return if essence.nil?

    authorize! :read, essence

    return unless Proxyist.exists? item.full_identifier, essence_filename

    Proxyist.get_object(item.full_identifier, essence_filename, download: true)
  end
end
