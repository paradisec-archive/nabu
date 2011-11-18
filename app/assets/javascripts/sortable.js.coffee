$(document).ready ->
  $('.sortable').click ->
    direction = $(this).data('direction')
    field = $(this).data('field')
    window.location.search = $.query.set('sort', field).set('direction', direction)
