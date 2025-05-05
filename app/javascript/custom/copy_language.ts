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

    for (const option of dstSelect.options) {
      option.selected = false;
    }

    for (const srcOption of srcSelect.options) {
      if (!srcOption.selected) {
        continue;
      }

      const dstOption = dstSelect.querySelector(`option[value="${srcOption.value}"]`) as HTMLOptionElement | null;
      if (dstOption) {
        dstOption.selected = true;

        continue;
      }

      const option = new Option(srcOption.text, srcOption.value, false, true);
      dstSelect.appendChild(option);
    }

    dstSelect.dispatchEvent(new Event('change'));
  });
};

document.addEventListener('DOMContentLoaded', () => {
  copyLanguage('subject', 'content');
  copyLanguage('content', 'subject');
});
