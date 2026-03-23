const existingExclusions = document.getElementById('existing_exclusions');
const hiddenExclusions = document.querySelectorAll('.exclusions');

document.querySelectorAll('[name="exclude[]"]').forEach((checkbox) => {
  checkbox.addEventListener('click', () => {
    const ids = [];
    document.querySelectorAll('[name="exclude[]"]:checked').forEach((checked) => {
      ids.push(checked.value);
    });

    const updateButton = document.getElementById('update_exclusions');
    if (updateButton) {
      updateButton.style.display = ids.length > 0 ? '' : 'none';
    }

    const allIds = existingExclusions ? ids.concat(existingExclusions.value) : ids;
    hiddenExclusions.forEach((el) => {
      el.value = allIds;
    });
  });
});

const updateButton = document.getElementById('update_exclusions');
if (updateButton) {
  updateButton.addEventListener('click', (event) => {
    event.preventDefault();
    document.querySelector('form').requestSubmit();
  });
}
