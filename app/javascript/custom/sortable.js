$(document).ready(() => {
  $('.sortable').click(() => {
    const direction = $(this).data('direction');
    const field = $(this).data('field');
    window.location.search = $.query.set('sort', field).set('direction', direction);
  });
});
