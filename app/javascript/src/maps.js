$(document).ready(() => {
  if (typeof google == 'object') {
    const set_map_bounds_from_ajax = (path, ids) => {
      let north_limit = null;
      let south_limit = null;
      let east_limit = null;
      let west_limit = null;

      const marker_bounds = new google.maps.LatLngBounds(); // eslint-disable-line no-undef

      // const map = $('.map').data('map');

      ids.forEach((id) => {
        let data = null;
        $.ajax({
          url: path + id + "?location_only=true",
          dataType: 'json',
          async: false,
          success: (object) => {
            data = object
          }
        });

        if (!data || !data['north_limit']) {
          return;
        }

        north_limit = data['north_limit'];
        south_limit = data['south_limit'];
        east_limit =  data['east_limit'];
        west_limit = data['west_limit'];

        const sw  = new google.maps.LatLng(south_limit, west_limit); // eslint-disable-line no-undef
        const ne  = new google.maps.LatLng(north_limit, east_limit); // eslint-disable-line no-undef
        marker_bounds.extend(sw);
        marker_bounds.extend(ne);
      });

      const ne = marker_bounds.getNorthEast();
      const sw = marker_bounds.getSouthWest();

      if (marker_bounds.isEmpty()) {
        displayNoDataMessage(path);
      } else {
        $('.north_limit').val(ne.lat());
        $('.east_limit').val(ne.lng());
        $('.south_limit').val(sw.lat());
        $('.west_limit').val(sw.lng());

        clearNoDataMessage();
        $('.map').trigger('update_map');
      }

      return false;
    }

    const displayNoDataMessage = (path) => {
      if (path == '/countries/') {
        $('.no-map-match-message').text('No matching map data found from country')
      } else {
        $('.no-map-match-message').text('No matching map data found from language')
      }
    };

    const clearNoDataMessage = () => {
      $('.no-map-match-message').text('')
    };

    $('#set-map-from-country').click(() => {
      const country_ids = $('.country').val().split(/,/);
      set_map_bounds_from_ajax('/countries/', country_ids);
    });

    $('#set-map-from-language').click(() => {
      const language_ids = $('.language').val().split(/,/)
      set_map_bounds_from_ajax('/languages/', language_ids);
    });

    $('.map').bind('update_map', () => {
      const north_limit = $('.north_limit').val() || $(this).data('north-limit') || 80;
      const south_limit = $('.south_limit').val() || $(this).data('south-limit') || -80;
      const east_limit = $('.east_limit').val() || $(this).data('east-limit') || -40;
      const west_limit = $('.west_limit').val() || $(this).data('west-limit') || -20;
      const editable = $(this).data('editable') == true;

      const sw  = new google.maps.LatLng(south_limit, west_limit); // eslint-disable-line no-undef
      const ne  = new google.maps.LatLng(north_limit, east_limit); // eslint-disable-line no-undef
      const bounds = new google.maps.LatLngBounds(sw, ne); // eslint-disable-line no-undef

      const map = $(this).data('map');
      map.fitBounds(bounds);

      let rect = $(this).data('rect');
      if (rect) {
        rect.setBounds(bounds)
      } else {
        rect = new google.maps.Rectangle({ // eslint-disable-line no-undef
          bounds: bounds,
          editable: editable,
          map: map
        });
        $(this).data('rect', rect);
      }

      google.maps.event.addListener(rect, 'bounds_changed', () => { // eslint-disable-line no-undef
        const bounds = rect.getBounds();
        const ne = bounds.getNorthEast();
        const sw = bounds.getSouthWest();
        $('.north_limit').val(ne.lat());
        $('.south_limit').val(sw.lat());
        $('.east_limit').val(ne.lng());
        $('.west_limit').val(sw.lng());
      })
    });

    $('.map').each((_, element) => {
      const cw = $(element).width();
      $(element).css({'height': cw + 'px'})

      const options = {
        mapTypeId: google.maps.MapTypeId.ROADMAP, // eslint-disable-line no-undef
        disableDefaultUI: true,
        scrollwheel: false,
        zoomControl: true,
        draggable: true,
        disableDoubleClickZoom: false,
      }

      const map = new google.maps.Map(element, options); // eslint-disable-line no-undef
      $(element).data('map', map)
      $(element).trigger('update_map')
    });

    $('.collection_map').each((_, element) => {
      const cw = $(element).width() - 100;
      $(element).css({'height':cw+'px'});

      const options = {
        center: new google.maps.LatLng(5, 140), // eslint-disable-line no-undef
        zoom: 1,
        mapTypeId: google.maps.MapTypeId.ROADMAP, // eslint-disable-line no-undef
        disableDefaultUI: true,
        scrollwheel: false,
        zoomControl: true,
        draggable: true,
        disableDoubleClickZoom: false,
      };

      const map = new google.maps.Map(element, options); // eslint-disable-line no-undef
      $(element).data('map', map);

      const north_limit = $(this).data('north-limit');
      const south_limit = $(this).data('south-limit');
      const east_limit = $(this).data('east-limit');
      const west_limit = $(this).data('west-limit');
      if (north_limit) {
        const sw  = new google.maps.LatLng(south_limit, west_limit); // eslint-disable-line no-undef
        const ne  = new google.maps.LatLng(north_limit, east_limit); // eslint-disable-line no-undef
        const bounds = new google.maps.LatLngBounds(sw, ne); // eslint-disable-line no-undef
        map.fitBounds(bounds);
      }

      const coordinates = $(element).data('coordinates');
      // const url = $(element).data('url');
      const cluster_options = {
        gridSize: 15,
        maxZoom: 15,
        avgCenter: false,
        minClusterSize: 5
      }
      const clusterer = new MarkerClusterer(map, [], cluster_options); // eslint-disable-line no-undef
      coordinates.forEach((coord) => {
        const latlng = new google.maps.LatLng(coord['lat'],coord['lng']); // eslint-disable-line no-undef

        // const link = url + '/' + coord['id'];
        // const items = coord['items'];
        const content = $(element).data('content')
          .replace(/TITLE/g, coord['title'])
          .replace(/ID/g, coord['id'])
          .replace(/ITEMS/g, coord['items']);

        const marker = new google.maps.Marker({ // eslint-disable-line no-undef
            position: latlng,
            title: coord['title'],
            clickable: true
        });
        marker.info = new google.maps.InfoWindow({ content: content }); // eslint-disable-line no-undef

        google.maps.event.addListener(marker, 'click', () => { // eslint-disable-line no-undef
          this.info.open(map, this)
        });

        clusterer.addMarker(marker);
    });
  });
  }
});
