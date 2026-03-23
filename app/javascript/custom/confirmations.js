document.querySelectorAll('form[data-confirm], button[data-confirm]').forEach((element) => {
  const eventType = element.tagName === 'FORM' ? 'submit' : 'click';
  element.addEventListener(eventType, (event) => {
    if (!window.confirm(element.dataset.confirm)) {
      event.preventDefault();
    }
  });
});
