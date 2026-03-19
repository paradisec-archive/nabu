import { setupChoices } from './choices_setup';

const init = () => {
  // Add more fields to form
  document.querySelector('a.add_fields')?.addEventListener('click', (event) => {
    const time = Date.now();
    const regexp = new RegExp(event.target.dataset.id, 'g');

    const newFields = event.target.dataset.fields.replace(regexp, time);
    event.target.insertAdjacentHTML('beforebegin', newFields);

    // Initialise any new select elements that haven't been set up yet
    event.target.parentElement?.querySelectorAll('.choices-select').forEach((el) => {
      if (!el.closest('.choices')) {
        setupChoices(el);
      }
    });

    event.preventDefault();
  });

  // Set up choices elements
  document.querySelectorAll('.choices-select').forEach((element) => {
    setupChoices(element);
  });
};

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
