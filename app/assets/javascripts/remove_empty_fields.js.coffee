$ ->
  $('form.no-empty-submit').submit ->
    $(this).find(':input[value=""]').attr('disabled', 'disabled')

    return true
