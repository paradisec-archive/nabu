import type Choices from 'choices.js';
import type { EventChoice } from 'choices.js';

interface Equivalent {
  value: string | number;
  label: string;
  description?: string;
  reason?: string;
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

  const render = () => {
    const tagged = instance.getValue() as EventChoice[];
    const taggedValues = new Set(tagged.map((choice) => String(choice.value)));
    const offered = new Map<string, Equivalent>();

    for (const choice of tagged) {
      for (const equivalent of equivalentsOf(choice)) {
        const value = String(equivalent.value);
        if (!taggedValues.has(value) && !offered.has(value)) {
          offered.set(value, equivalent);
        }
      }
    }

    chips.replaceChildren(...Array.from(offered.values(), (equivalent) => buildChip(equivalent, instance)));
  };

  select.addEventListener('addItem', render);
  select.addEventListener('removeItem', render);

  render();
};
