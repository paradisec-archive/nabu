import { getChoicesInstance } from './choices_setup';

const copyLanguage = (src: string, dst: string) => {
  const button = document.getElementById(`copy-${dst}-language`) as HTMLAnchorElement | null;
  if (!button) {
    return;
  }

  button.addEventListener('click', (event) => {
    event.preventDefault();

    const srcSelect = document.getElementById(`item_${src}_language_ids`) as HTMLSelectElement | null;
    if (!srcSelect) {
      throw new Error(`Select element with id item_${src}_language_ids not found`);
    }

    const dstSelect = document.getElementById(`item_${dst}_language_ids`) as HTMLSelectElement | null;
    if (!dstSelect) {
      throw new Error(`Select element with id item_${dst}_language_ids not found`);
    }

    const dstInstance = getChoicesInstance(dstSelect);

    // Collect selected options from source
    const selectedOptions: { value: string; label: string }[] = [];
    for (const srcOption of srcSelect.selectedOptions) {
      selectedOptions.push({ value: srcOption.value, label: srcOption.text });
    }

    if (!dstInstance) {
      throw new Error('Choices.js instance not found for destination select');
    }

    dstInstance.removeActiveItems();

    // Add choices that may not exist yet (AJAX-loaded), then select them
    dstInstance.setChoices(selectedOptions, 'value', 'label', true);
    for (const opt of selectedOptions) {
      dstInstance.setChoiceByValue(opt.value);
    }
  });
};

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    copyLanguage('subject', 'content');
    copyLanguage('content', 'subject');
  });
} else {
  copyLanguage('subject', 'content');
  copyLanguage('content', 'subject');
}
