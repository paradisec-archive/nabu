$(() => {
  $('#copy-subject-language').on('click', () => {
    $('#item_subject_language_ids').select2('val', $('#item_content_language_ids').select2('val'), true);

    return false;
  });


  $('#copy-content-language').on('click', () => {
    $('#item_content_language_ids').select2('val', $('#item_subject_language_ids').select2('val'), true);

    return false;
  });
});
