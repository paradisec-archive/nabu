document.querySelectorAll('button[data-confirm-delete-message]').forEach((button) => {
  button.addEventListener('click', (event) => {
    event.preventDefault();

    const confirmMessage = button.dataset.confirmDeleteMessage;
    const isConfirmed = window.confirm(confirmMessage);
    if (isConfirmed) {
      button.closest('form').submit();
    }
  });
});
