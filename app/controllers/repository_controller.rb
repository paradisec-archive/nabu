require 'ostruct'
require 'media'

class RepositoryController < ApplicationController
  include MediaStreaming

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
    essence = item.essences.find_by_filename params[:essence_filename]

    # if a standard essence file was found, return that as usual
    if essence.present?
      authorize! :read, essence
      return send_essence(essence)

    # otherwise look up to see if there is a hidden admin file (thumbnails, soundimage file, etc.)
    elsif params[:essence_filename].include?('PDSC_ADMIN')
      admin_essence = send_admin_essence(collection, item, params[:essence_filename])
      return admin_essence if admin_essence
    end

    raise ActionController::RoutingError, "Repository file not found: #{params[:essence_filename]}"
  end

  private

  # this expects any admin-style files to have a name of the form "<essence identifier part>-<type>-PDSC_ADMIN.<extension>"
  # e.g. AA1-001-essence-file-goes-here-thumb-PDSC_ADMIN.jpg where collection AA1 has item 001 with essence "essence-file-goes-here"
  def send_admin_essence(collection, item, essence_filename)
    item_prefix = "#{collection.identifier}-#{item.identifier}-"
    essence_part = essence_filename.sub(item_prefix, '').sub(/^(.+?)-[^-]+?-PDSC_ADMIN\..+/, '\1')
    essence = item.essences.where('filename LIKE :prefix', prefix: "#{item_prefix}#{essence_part}%").first

    # don't allow the user to randomly access data, must relate directly to an essence file
    return if essence.nil?

    authorize! :read, essence

    admin_file_path = "#{Nabu::Application.config.archive_directory}/#{collection.identifier}/#{item.identifier}/#{essence_filename}"
    if File.file? admin_file_path
      stats = Nabu::Media.new(admin_file_path)

      # use OpenStruct to create a fake essence file, this allows us to reuse the existing send_essence method
      admin_essence = OpenStruct.new
      admin_essence.path = admin_file_path
      admin_essence.size = stats.size
      admin_essence.filename = essence_filename
      admin_essence.mimetype = stats.mimetype

      send_essence(admin_essence)
    end
  end
end
