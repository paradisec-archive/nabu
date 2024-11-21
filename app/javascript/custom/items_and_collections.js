import { setup_select2 } from './select2_setup';

$(() => {
  // Add more fields to form
  document.querySelector('a.add_fields')?.addEventListener('click', (event) => {
    const time = new Date().getTime();
    const regexp = new RegExp(event.target.dataset.id, 'g');

    const newFields = event.target.dataset.fields.replace(regexp, time);
    event.target.insertAdjacentHTML('beforebegin', newFields);
    setup_select2(event.target.previousElementSibling.previousElementSibling);
    setup_select2(event.target.previousElementSibling);
    event.preventDefault();
  });

  // Set up select2 elements
  document.querySelectorAll('.select2').forEach((element) => setup_select2(element));
});
