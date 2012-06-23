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
      latitude  = $(element).data('latitude') || 0
      longitude = $(element).data('longitude') || 0
      zoom      = $(element).data('zoom') || 1
      editable  = $(element).data('editable')

      lat_long  = new google.maps.LatLng(latitude, longitude)
      options = {
        center:    lat_long,
        zoom:      zoom,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        disableDefaultUI: true,
      }

      if editable
        options['zoomControl'] = true
      else
        options['draggable'] = false
        options['scrollwheel'] = false
        options['disableDoubleClickZoom'] = true


      map = new google.maps.Map(element, options)
      $(element).data('map', map)

      google.maps.event.addListener map, 'center_changed', ->
        $('.longitude').val map.getCenter().lng()
        $('.latitude').val map.getCenter().lat()
        $('.zoom').val map.getZoom()

      google.maps.event.addListener map, 'zoom_changed', ->
        $('.longitude').val map.getCenter().lng()
        $('.latitude').val map.getCenter().lat()
        $('.zoom').val map.getZoom()

