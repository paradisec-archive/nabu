$(function () {
  $('form.no-empty-submit').submit(function () {
    $(this).find('input, select, textarea').each((_, element) => {
      if (element.value == '') {
        element.disabled = 'disabled'
      }
    });

    return true;
  });
});
