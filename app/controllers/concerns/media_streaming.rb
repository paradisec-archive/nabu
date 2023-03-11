module MediaStreaming
  def send_essence(essence)
    # file_begin = 0
    # file_size = essence.size
    # file_end = file_size - 1
    # if !request.headers["Range"]
    #   status_code = 200
    # else
    #   status_code = 206
    #   match = request.headers['range'].match(/bytes=(\d+)-(\d*)/)
    #
    #   if match
    #     file_begin = match[1]
    #     file_end = match[2] if match[2] && !match[2].empty?
    #   end
    #
    #   response.header["Content-Range"] = "bytes " + file_begin.to_s + "-" + file_end.to_s + "/" + file_size.to_s
    # end
    #
    # response.header["Content-Length"] = (file_end.to_i - file_begin.to_i + 1).to_s

    # these two lines force Rack::Cache to not cache the response so that we don't end up with GBs of Rails.root/tmp/cache
    # response.header["Last-Modified"] = Time.now.ctime.to_s
    # response.header["Cache-Control"] = 'private,max-age=0,must-revalidate,no-store'
    # end cache override

    # response.header["Pragma"] = "no-cache"
    # response.header["Accept-Ranges"] =  "bytes"
    # response.header["Content-Transfer-Encoding"] = "binary"

    # if status_code == 200
      send_file(
          essence.path,
          :filename => essence.filename,
          :type => essence.mimetype
          # :status => status_code,
      )
    # else
    #   send_data(
    #       IO.binread(essence.path, file_end.to_i - file_begin.to_i + 1, file_begin.to_i),
    #       :type => essence.mimetype,
    #       :status => status_code
    #   )
    # end
  end
end
