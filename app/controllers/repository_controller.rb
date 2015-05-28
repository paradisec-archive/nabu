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
    essence = item.essences.find_by_filename params[:essence_filename]

    authorize! :read, essence

    send_essence(essence)
  end

  private

  def send_essence(essence)
    file_begin = 0
    file_size = essence.size
    file_end = file_size - 1

    if !request.headers["Range"]
      status_code = "200 OK"
    else
      status_code = "206 Partial Content"
      match = request.headers['range'].match(/bytes=(\d+)-(\d*)/)

      if match
        file_begin = match[1]
        file_end = match[1] if match[2] && !match[2].empty?
      end

      response.header["Content-Range"] = "bytes " + file_begin.to_s + "-" + file_end.to_s + "/" + file_size.to_s
    end

    response.header["Content-Length"] = (file_end.to_i - file_begin.to_i + 1).to_s
    response.header["Last-Modified"] = essence.updated_at.to_s

    response.header["Cache-Control"] = "public, must-revalidate, max-age=0"
    response.header["Pragma"] = "no-cache"
    response.header["Accept-Ranges"] =  "bytes"
    response.header["Content-Transfer-Encoding"] = "binary"

    send_file(
      essence.path,
      :filename => essence.filename,
      :type => essence.mimetype,
      :disposition => "inline",
      :status => status_code,
      :stream =>  'true',
      :buffer_size  =>  4096
     )
  end
end
