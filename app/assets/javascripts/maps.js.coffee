$(document).ready ->
  if (typeof google == 'object')
    $('#set-map-from-language').click ->
      language_ids = $('.language').val().split(/,/)
      north_limit = null
      south_limit = null
      east_limit = null
      west_limit = null
      for language_id in language_ids
        data = {}
        $.ajax(
          url: '/languages/' + language_id,
          dataType: 'json',
          async: false,
          success: (object) ->
            data = object
        )
        north_limit ||= data['north_limit']
        south_limit ||= data['south_limit']
        east_limit ||=  data['east_limit']
        west_limit ||= data['west_limit']

        if data['north_limit'] > north_limit
          north_limit = data['north_limit']
        if data['south_limit'] < south_limit
          south_limit = data['south_limit']
        if data['east_limit'] > east_limit
          east_limit = data['east_limit']
        if data['west_limit'] < west_limit
          west_limit = data['west_limit']

        $('.north_limit').val(north_limit)
        $('.south_limit').val(south_limit)
        $('.east_limit').val(east_limit)
        $('.west_limit').val(west_limit)

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

