$(document).ready ->
  $('button.per_page').click ->
    per_page = $(this).data('per')
    window.location.search = $.query.set('per_page', per_page)
