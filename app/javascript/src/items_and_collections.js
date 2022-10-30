$(document).ready(() => {

  // Add more fields to form
  $('form').on('click', '.add_fields', (event) => {
    const time = new Date().getTime()
    const regexp = new RegExp($(this).data('id'), 'g')

    $(this).before($(this).data('fields').replace(regexp, time));
    setup_select2($(this).prev().prev()); // eslint-disable-line no-undef
    setup_select2($(this).prev()); // eslint-disable-line no-undef
    event.preventDefault();
  });


  // Set up select2 elements
  $(".select2").each(() => {
    setup_select2(this); // eslint-disable-line no-undef
  });

  // Fix _ids hidden fields for select2
  $('form').submit(() => {
    const form = $(this)
    form.find('input[type=hidden].select2').each(() => {
      if ($(this).attr('name').match(/_ids]$/) && $(this).val() != '') {
        const ids = $(this).val().split(/,/);
        ids.forEach((id) => {
          form.append($('<input type=hidden name="' + $(this).attr('name') + '[]" value="' + id + '" />'));
          $(this).remove();
        });
      }
    });
  });
});
