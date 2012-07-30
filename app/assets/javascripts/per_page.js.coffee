$(document).ready ->
  $('button.per_page').click ->
    per_page = $(this).data('per')
    param_name = $(this).data('param_name') || 'per_page'
    window.location.search = $.query.set(param_name, per_page)
