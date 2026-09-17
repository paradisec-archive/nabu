import Choices from 'choices.js';

import { addFundingBody } from './dynamic_grant_identifiers';
import { setupEquivalentChips } from './language_equivalents';

interface SearchDetail {
  value: string;
}

interface SearchResult {
  value: string | number;
  label: string;
  description?: string;
  custom_properties?: object;
}

interface PickerChoice {
  value: string;
  label: string;
  labelDescription?: string;
  customProperties?: object;
}

const instanceMap = new Map<HTMLSelectElement, Choices>();

const debounce = (fn: (...args: unknown[]) => void, delay: number) => {
  let timer: ReturnType<typeof setTimeout>;
  return (...args: unknown[]) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
};

const setupAjaxSearch = (element: HTMLSelectElement, instance: Choices) => {
  const url = element.dataset.searchUrl;
  if (!url) {
    return;
  }

  const extraName = element.dataset.extraName;
  const extraSelector = element.dataset.extraSelector;
  const hasTags = element.dataset.tags === 'true';
  const excludeContacts = element.dataset.excludeContacts === 'true';
  let abortController: AbortController | null = null;

  const doSearch = debounce(async (_detail: unknown) => {
    const { value: searchTerm } = _detail as SearchDetail;

    abortController?.abort();
    abortController = new AbortController();

    const params = new URLSearchParams({ q: searchTerm });

    if (excludeContacts) {
      params.append('exclude_contacts', 'true');
    }

    if (extraName && extraSelector) {
      const extraElement = document.querySelector(extraSelector) as HTMLSelectElement | null;
      if (extraElement) {
        for (const option of extraElement.selectedOptions) {
          params.append(extraName, option.value);
        }
      }
    }

    try {
      const response = await fetch(`${url}?${params.toString()}`, { signal: abortController.signal });
      const data = (await response.json()) as { results: SearchResult[] };

      let choices: PickerChoice[] = data.results.map(({ value, label, description, custom_properties }) => ({
        value: String(value),
        label,
        labelDescription: description,
        customProperties: custom_properties,
      }));

      if (hasTags && searchTerm.trim() !== '') {
        choices = [{ value: `NEWCONTACT:${searchTerm.trim()}`, label: `Create new contact: ${searchTerm.trim()}` }, ...choices];
      }

      instance.setChoices(choices, 'value', 'label', true);
    } catch (error) {
      if (error instanceof DOMException && error.name === 'AbortError') {
        return;
      }
      console.error('Choices.js AJAX search failed:', error);
    }
  }, 300);

  instance.passedElement.element.addEventListener('search', ((event: CustomEvent) => {
    doSearch(event.detail);
  }) as EventListener);
};

export const setupChoices = (element: HTMLSelectElement): Choices => {
  const existing = instanceMap.get(element);
  if (existing) {
    return existing;
  }

  const hasAjax = !!element.dataset.searchUrl;

  const options: Partial<Choices['config']> = {
    removeItemButton: true,
    shouldSort: false,
    noResultsText: hasAjax ? 'Type to search...' : 'No results found',
    noChoicesText: hasAjax ? 'Type to search...' : 'No choices to choose from',
  };

  if (hasAjax) {
    options.searchChoices = false;
  }

  const instance = new Choices(element, options);

  instanceMap.set(element, instance);

  if (hasAjax) {
    setupAjaxSearch(element, instance);
  }

  if (element.dataset.equivalents === 'true') {
    setupEquivalentChips(element, instance);
  }

  if (element.dataset.changeAction === 'funding-body') {
    element.addEventListener('change', (event: Event) => {
      addFundingBody(event);
    });
  }

  return instance;
};

export const getChoicesInstance = (element: HTMLSelectElement): Choices | undefined => {
  return instanceMap.get(element);
};
