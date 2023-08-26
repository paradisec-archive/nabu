$(function() {
  $('button[data-confirm-delete-message]').on('click', function(event) {
    event.preventDefault();

    const confirmMessage = $(this).data('confirm-delete-message');
    const isConfirmed = window.confirm(confirmMessage);
    if (isConfirmed) {
      $(this).closest('form')[0].submit();
    }
  });
});
