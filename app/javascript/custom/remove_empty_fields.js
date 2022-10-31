$(document).ready(() => {
  $('form.no-empty-submit').submit(() => {
    $(this).find('input, select, textarea').each((_, element) => {
      if (element.value == '') {
        element.disabled = 'disabled'
      }
    });

    return true;
  });
});
