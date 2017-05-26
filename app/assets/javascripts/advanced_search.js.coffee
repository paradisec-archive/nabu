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

    # if new ids have been checked, then show button
    if (ids.length > 0)
      $('#update_exclusions').show()
    else
      $('#update_exclusions').hide()

    ids = ids.concat(existingExclusions.val())

    hiddenExclusions.val(ids)

  $('#update_exclusions').click ->
    $('.drawer:not(.closed) form').submit()
    return false
