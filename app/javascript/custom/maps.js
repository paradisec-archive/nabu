import { Loader } from "@googlemaps/js-api-loader"
import { MarkerClusterer } from '@googlemaps/markerclusterer';

const apiKey = $("body").data('rails-env') === 'development' ? undefined : $("body").data("google-maps-api-key");
const loader = new Loader({
  apiKey,
  version: "weekly",
});

loader.load().then(async () => {
  const set_map_bounds_from_ajax = async (path, ids) => {
    const marker_bounds = new google.maps.LatLngBounds();

    for (const id of ids) {
      // TOOD: Do we have to set data type as json?
      const response = await fetch(`${path}${id}?location_only=true`);
      const data = await response.json();

      if (!data || !data.north_limit) {
        console.info('NO data', data);
        return;
      }

      const { north_limit, south_limit, east_limit, west_limit } = data;

      const sw = new google.maps.LatLng(south_limit, west_limit);
      const ne = new google.maps.LatLng(north_limit, east_limit);
      marker_bounds.extend(sw);
      marker_bounds.extend(ne);
    }

    if (marker_bounds.isEmpty()) {
      const node = document.querySelector('.no-map-match-message');
      node.textContent = `No matching map data found from ${path === '/countries/' ? 'country' : 'language'}`;

      return;
    }

    const ne = marker_bounds.getNorthEast();
    const sw = marker_bounds.getSouthWest();

    document.querySelector('.north_limit').value = ne.lat();
    document.querySelector('.east_limit').value = ne.lng();
    document.querySelector('.south_limit').value = sw.lat();
    document.querySelector('.west_limit').value = sw.lng();

    document.querySelector('.no-map-match-message').textContent = '';

    document.querySelector('.map').dispatchEvent(new Event('update_map'));

    return false;
  };

  document.querySelector('#set-map-from-country')?.addEventListener('click', (event) => {
    event.preventDefault();

    const country_ids = document.querySelector('.country').value.split(/,/);
    set_map_bounds_from_ajax('/countries/', country_ids);
  });

  document.querySelector('#set-map-from-language')?.addEventListener('click', (event) => {
    event.preventDefault();

    const language_ids = document.querySelector('.language').value.split(/,/);
    set_map_bounds_from_ajax('/languages/', language_ids);
  });

  document.querySelector('.map')?.addEventListener('update_map', (event) => {
    const north_limit = document.querySelector('.north_limit')?.value || event.target.dataset.northLimit || 80;
    const south_limit = document.querySelector('.south_limit')?.value || event.target.dataset.southLimit || -80;
    const east_limit = document.querySelector('.east_limit')?.value || event.target.dataset.eastLimit || -40;
    const west_limit = document.querySelector('.west_limit')?.value || event.target.dataset.westLimit || -20;
    const editable = event.target.dataset.editable === 'true';

    const sw = new google.maps.LatLng(south_limit, west_limit);
    const ne = new google.maps.LatLng(north_limit, east_limit);
    const bounds = new google.maps.LatLngBounds(sw, ne);

    const map = event.target.map;
    map.fitBounds(bounds);

    let rect = event.target.rect;
    if (rect) {
      rect.setBounds(bounds);
    } else {
      rect = new google.maps.Rectangle({
        bounds: bounds,
        editable: editable,
        map: map,
      });
      event.target.rect = rect;
    }

    google.maps.event.addListener(rect, 'bounds_changed', () => {
      // eslint-disable-line no-undef
      const bounds = rect.getBounds();
      const ne = bounds.getNorthEast();
      const sw = bounds.getSouthWest();
      document.querySelector('.north_limit').value = ne.lat();
      document.querySelector('.south_limit').value = sw.lat();
      document.querySelector('.east_limit').value = ne.lng();
      document.querySelector('.west_limit').value = sw.lng();
    });
  });

  document.querySelectorAll('.map').forEach((element) => {
    const cw = element.getBoundingClientRect().width;
    element.style.height = `${cw}px`;
    element.style.maxHeight = '400px';

    const options = {
      mapTypeId: google.maps.MapTypeId.ROADMAP, // eslint-disable-line no-undef
      disableDefaultUI: true,
      scrollwheel: false,
      zoomControl: true,
      draggable: true,
      disableDoubleClickZoom: false,
    };

    const map = new google.maps.Map(element, options); // eslint-disable-line no-undef
    element.map = map;
    element.dispatchEvent(new Event('update_map'));
  });

  document.querySelectorAll('.collection_map').forEach((element) => {
    const cw = element.getBoundingClientRect().width - 100;
    element.style.height = `${cw}px`;

    const options = {
      center: new google.maps.LatLng(5, 140),
      zoom: 1,
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      disableDefaultUI: true,
      scrollwheel: false,
      zoomControl: true,
      draggable: true,
      disableDoubleClickZoom: false,
    };

    const map = new google.maps.Map(element, options);
    element.map = map;

    const north_limit = element.dataset.northLimit;
    const south_limit = element.dataset.southLimit;
    const east_limit = element.dataset.eastLimit;
    const west_limit = element.dataset.westLimit;
    if (north_limit) {
      const sw = new google.maps.LatLng(south_limit, west_limit);
      const ne = new google.maps.LatLng(north_limit, east_limit);
      const bounds = new google.maps.LatLngBounds(sw, ne);
      map.fitBounds(bounds);
    }

    const clusterer = new MarkerClusterer({ map });

    const coordinates = JSON.parse(element.dataset.coordinates || []);
    coordinates.forEach((coord) => {
      const latlng = new google.maps.LatLng(coord.lat, coord.lng);

      const content = element.dataset.content
        .replace(/TITLE/g, coord.title)
        .replace(/ID/g, coord.id)
        .replace(/ITEMS/g, coord.items);

      const marker = new google.maps.Marker({
        position: latlng,
        title: coord.title,
        clickable: true,
      });
      marker.info = new google.maps.InfoWindow({ content: content });

      google.maps.event.addListener(marker, 'click', () => {
        marker.info.open(map, marker);
      });

      clusterer.addMarker(marker);
    });
  });
});
