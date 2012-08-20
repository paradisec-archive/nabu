$(document).ready ->
  if (typeof google == 'object')
    $('.map_search').keypress (event) ->
      return unless event.keyCode == 13


      query = $('.map_search').val()

      map = $('.map').data('map')

      geocoder = new google.maps.Geocoder()
      geocoder.geocode { 'address': query}, (results, status) ->
        if status == google.maps.GeocoderStatus.OK
          map.fitBounds(results[0].geometry.viewport)
        else
          alert("Could not find that location")

      false

    $('.map').each (index, element) ->
      north_limit = $(element).data('north_limit') || 90
      south_limit = $(element).data('south_limit') || -90
      west_limit = $(element).data('west_limit') || -180
      east_limit = $(element).data('east_limit') || 180
      if $(element).data('editable')
        editable = true
      else
        editable = false

      sw  = new google.maps.LatLng(south_limit, west_limit)
      ne  = new google.maps.LatLng(north_limit, east_limit)
      bounds = new google.maps.LatLngBounds(sw, ne)

      options = {
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        disableDefaultUI: true,
        scrollwheel: false,
        zoomControl: true,
        draggable: true,
        disableDoubleClickZoom: false,
      }

      map = new google.maps.Map(element, options)
      map.fitBounds(bounds)

      rect = new google.maps.Rectangle({
        bounds: bounds,
        editable: editable,
        map: map
        # TODO Add colors etc
      })

      $(element).data('map', map)

      google.maps.event.addListener map, 'center_changed', ->
        $('.longitude').val map.getCenter().lng()
        $('.latitude').val map.getCenter().lat()
        $('.zoom').val map.getZoom()

      google.maps.event.addListener map, 'zoom_changed', ->
        $('.longitude').val map.getCenter().lng()
        $('.latitude').val map.getCenter().lat()
        $('.zoom').val map.getZoom()

