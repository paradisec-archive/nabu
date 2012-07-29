$ ->
  $('#copy-subject-language').click ->
    $('#item_subject_language_ids').val($('#item_content_language_ids').val())

    # Tell chosen we changed the list
    $('#item_subject_language_ids').trigger('change')

    false


  $('#copy-content-language').click ->
    $('#item_content_language_ids').val($('#item_subject_language_ids').val())

    # Tell chosen we changed the list
    $('#item_content_language_ids').trigger('change')

    false
