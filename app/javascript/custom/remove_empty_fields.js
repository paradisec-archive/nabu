document.querySelectorAll('form.no-empty-submit').forEach((form) => {
  form.addEventListener('submit', () => {
    form.querySelectorAll('input, select, textarea').forEach((element) => {
      if (element.value === '') {
        element.disabled = true;
      }
    });
  });
});
