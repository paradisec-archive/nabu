$(document).ready ->
  if (typeof google == 'object')
    $('#set-map-from-language').click ->
      language_ids = $('.language').val().split(/,/)
      north_limit = null
      south_limit = null
      east_limit = null
      west_limit = null

      marker_bounds = new google.maps.LatLngBounds()

      map = $('.map').data('map')

      for language_id in language_ids
        data = {}
        $.ajax(
          url: '/languages/' + language_id,
          dataType: 'json',
          async: false,
          success: (object) ->
            data = object
        )

        if !data['north_limit']
          continue

        north_limit = data['north_limit']
        south_limit = data['south_limit']
        east_limit =  data['east_limit']
        west_limit = data['west_limit']

        sw  = new google.maps.LatLng(south_limit, west_limit)
        ne  = new google.maps.LatLng(north_limit, east_limit)
        marker_bounds.extend(sw)
        marker_bounds.extend(ne)

      ne = marker_bounds.getNorthEast()
      sw = marker_bounds.getSouthWest()

      if marker_bounds.isEmpty()
        $('.north_limit').val(70)
        $('.east_limit').val(170)
        $('.south_limit').val(-70)
        $('.west_limit').val(-170)
      else
        $('.north_limit').val(ne.lat())
        $('.east_limit').val(ne.lng())
        $('.south_limit').val(sw.lat())
        $('.west_limit').val(sw.lng())

      $('.map').trigger('update_map')
      false

    $('.map').bind 'update_map', (event) ->
      north_limit = $('.north_limit').val() || $(this).data('north_limit') || 70
      south_limit = $('.south_limit').val() || $(this).data('south_limit') || -70
      east_limit = $('.east_limit').val() || $(this).data('east_limit') || 170
      west_limit = $('.west_limit').val() || $(this).data('west_limit') || -170
      editable = $(this).data('editable') == true

      sw  = new google.maps.LatLng(south_limit, west_limit)
      ne  = new google.maps.LatLng(north_limit, east_limit)
      bounds = new google.maps.LatLngBounds(sw, ne)

      map = $(this).data('map')
      map.fitBounds(bounds)

      rect = $(this).data('rect')
      if rect
        rect.setBounds(bounds)
      else
        rect = new google.maps.Rectangle({
          bounds: bounds,
          editable: editable,
          map: map
          # TODO Add colors etc
        })
        $(this).data('rect', rect)

      google.maps.event.addListener rect, 'bounds_changed', ->
        bounds = rect.getBounds()
        ne = bounds.getNorthEast()
        sw = bounds.getSouthWest()
        $('.north_limit').val(ne.lat())
        $('.south_limit').val(sw.lat())
        $('.east_limit').val(ne.lng())
        $('.west_limit').val(sw.lng())

    $('.map').each (index, element) ->
      cw = $(element).width()
      $(element).css({'height':cw+'px'})

      options = {
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        disableDefaultUI: true,
        scrollwheel: false,
        zoomControl: true,
        draggable: true,
        disableDoubleClickZoom: false,
      }

      map = new google.maps.Map(element, options)
      $(element).data('map', map)
      $(element).trigger('update_map')

    $('.collection_map').each (index, element) ->
      cw = $(element).width() - 100
      $(element).css({'height':cw+'px'})

      options = {
        center: new google.maps.LatLng(20, 0),
        zoom: 1,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        disableDefaultUI: true,
        scrollwheel: false,
        zoomControl: true,
        draggable: true,
        disableDoubleClickZoom: false,
      }

      map = new google.maps.Map(element, options)
      $(element).data('map', map)

      north_limit = $(this).data('north_limit')
      south_limit = $(this).data('south_limit')
      east_limit = $(this).data('east_limit')
      west_limit = $(this).data('west_limit')
      if north_limit
        sw  = new google.maps.LatLng(south_limit, west_limit)
        ne  = new google.maps.LatLng(north_limit, east_limit)
        bounds = new google.maps.LatLngBounds(sw, ne)
        map.fitBounds(bounds)

      coordinates = $(element).data('coordinates')
      url = $(element).data('url')
      cluster_options = {
        gridSize: 15,
        maxZoom: 15,
        avgCenter: false,
        minClusterSize: 5
      }
      clusterer = new MarkerClusterer(map, [], cluster_options)
      for coord in coordinates
        latlng = new google.maps.LatLng(coord['lat'],coord['lng'])

        link = url + '/' + coord['id']
        items = coord['items']
        content = $(element).data('content')
        content = content.replace(/TITLE/g, coord['title'])
        content = content.replace(/ID/g, coord['id'])
        content = content.replace(/ITEMS/g, coord['items'])

        marker = new google.maps.Marker({
            position: latlng,
            title: coord['title'],
            clickable: true
        })
        marker.info = new google.maps.InfoWindow(content: content)

        google.maps.event.addListener marker, 'click', ->
          this.info.open(map, this)

        clusterer.addMarker(marker)


