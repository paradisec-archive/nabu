import type Choices from 'choices.js';
import type { EventChoice } from 'choices.js';

interface Equivalent {
  value: string | number;
  label: string;
  description?: string;
  reason?: string;
  collapsed?: boolean;
  custom_properties?: object;
}

// Every Language a form offers carries its own Equivalents as Choices.js custom properties, whether
// it was rendered with the page or picked after it.
const equivalentsOf = (choice: EventChoice): Equivalent[] => (choice.customProperties as { equivalents?: Equivalent[] })?.equivalents ?? [];

const buildChip = (equivalent: Equivalent, instance: Choices) => {
  const chip = document.createElement('button');
  chip.type = 'button';
  chip.className = 'link-button language-equivalent';
  chip.textContent = `Also add: ${equivalent.label}`;
  if (equivalent.reason) {
    chip.title = equivalent.reason;
  }
  if (equivalent.description) {
    chip.dataset.labelDescription = equivalent.description;
  }
  if (equivalent.collapsed) {
    chip.dataset.collapsed = '';
  }

  chip.addEventListener('click', () => {
    const value = String(equivalent.value);

    // The Language may never have been a hit in this field's picker, so it is offered as a choice
    // before it is chosen, carrying its own Equivalents so that its chips render in turn.
    const choice = { value, label: equivalent.label, labelDescription: equivalent.description, customProperties: equivalent.custom_properties };
    instance.setChoices([choice], 'value', 'label', false);
    instance.setChoiceByValue(value);
  });

  return chip;
};

export const setupEquivalentChips = (select: HTMLSelectElement, instance: Choices) => {
  const chips = document.getElementById(`${select.id}_equivalents`);
  if (!chips) {
    return;
  }

  // Collapsed chips are hidden by CSS until this field's toggle is ticked.
  const toggle = document.createElement('label');
  toggle.className = 'language-equivalents-dialects hidden';
  const checkbox = document.createElement('input');
  checkbox.type = 'checkbox';
  checkbox.addEventListener('change', () => chips.classList.toggle('show-collapsed', checkbox.checked));
  const count = document.createTextNode('');
  toggle.append(checkbox, count);
  chips.after(toggle);

  const render = () => {
    const tagged = instance.getValue() as EventChoice[];
    const taggedValues = new Set(tagged.map((choice) => String(choice.value)));
    const offered = new Map<string, Equivalent>();

    for (const choice of tagged) {
      for (const equivalent of equivalentsOf(choice)) {
        const value = String(equivalent.value);
        const existing = offered.get(value);
        // A dialect offered on stronger evidence by another tagged Language is not collapsed.
        if (!taggedValues.has(value) && (!existing || (existing.collapsed && !equivalent.collapsed))) {
          offered.set(value, equivalent);
        }
      }
    }

    const all = Array.from(offered.values());
    const collapsed = all.filter((equivalent) => equivalent.collapsed).length;

    toggle.classList.toggle('hidden', collapsed === 0);
    count.data = ` Show dialects (${collapsed})`;
    chips.replaceChildren(...all.map((equivalent) => buildChip(equivalent, instance)));
  };

  select.addEventListener('addItem', render);
  select.addEventListener('removeItem', render);

  render();
};
