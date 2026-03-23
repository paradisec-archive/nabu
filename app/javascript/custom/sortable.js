document.querySelectorAll('.sortable').forEach((element) => {
  element.addEventListener('click', () => {
    const direction = element.dataset.direction;
    const field = element.dataset.field;
    const params = new URLSearchParams(window.location.search);
    params.set('sort', field);
    params.set('direction', direction);
    window.location.search = params.toString();
  });
});
