$ ->
  $('form.no-empty-submit').submit ->
    # This is not quite perfect. The select 2 identifiers still get sent
    $(this).find('input').each (index, element) ->
      if element.value == ''
        element.disabled = 'disabled'

    return true
