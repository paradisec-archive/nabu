$(() => {
  $('.sortable').on('click', function () {
    const direction = $(this).data('direction');
    const field = $(this).data('field');
    window.location.search = $.query.set('sort', field).set('direction', direction);
  });
});
