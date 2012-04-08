$ ->
  $('select.country').live 'change', ->
    ids = []
    $('select.country option:selected').each ->
      ids.push $(this).attr('value')

    $('select.language').each ->
      $(this).find('option').attr('disabled', 'disabled')
      for id in ids
        $(this).find('option[data-country_id=' + id + ']').removeAttr('disabled').insertBefore($(this).children().first())
      $(this).find('option:selected').insertBefore($(this).children().first())
