$(function () {
  const existingExclusions = $('#existing_exclusions');
  const hiddenExclusions = $('.exclusions');

  $('.drawer-toggle').on('click', function () {
    $('.drawer').toggleClass('closed');
    $('.drawer-toggle').toggleClass('hidden');
    return false;
  });

  $('[name="exclude[]"]').on('click', function () {
    let ids = [];
    $('[name="exclude[]"]:checked').each(function () {
      ids.push($(this).val());
    });

    // if new ids have been checked, then show button
    if (ids.length > 0) {
      $('#update_exclusions').show();
    } else {
      $('#update_exclusions').hide();
    }

    ids = ids.concat(existingExclusions.val())

    hiddenExclusions.val(ids)
  });

  $('#update_exclusions').on('click', function () {
    $('.drawer:not(.closed) form').submit();
    return false;
  });
});
