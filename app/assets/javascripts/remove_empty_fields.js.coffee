$ ->
  $('form').submit ->
    $(this).find(':input[value=""]').attr('disabled', 'disabled')

    return true
