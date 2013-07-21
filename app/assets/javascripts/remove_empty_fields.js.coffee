$ ->
  $('form.no-empty-submit').submit ->
    $(this).find('input, select, textarea').each (index, element) ->
      if element.value == ''
        element.disabled = 'disabled'

    return true
