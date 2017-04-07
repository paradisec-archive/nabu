$(document).ready ->
  existingExclusions = $('#existing_exclusions')
  hiddenExclusions = $('.exclusions')

  $('.drawer-toggle').click ->
    $('.drawer').toggleClass('closed')
    $('.drawer-toggle').toggleClass('hidden')
    return false

  $('[name="exclude[]"]').click ->
    ids = []
    $('[name="exclude[]"]:checked').each ->
        ids.push($(this).val())
    ids = ids.concat(existingExclusions.val())

    hiddenExclusions.val(ids)
