import { v4 as uuidv4 } from 'uuid';

export const addFundingBody = (event: Event) => {
  const fundingBodySelect = event.target as HTMLSelectElement;
  const fundingBodyId = fundingBodySelect.value;
  const fundingBodyName = fundingBodySelect.selectedOptions[0].label;

  if (fundingBodyId.length === 0) {
    return;
  }

  const fundingBodies = document.getElementById('funding-bodies');
  if (!fundingBodies) {
    return;
  }

  if (fundingBodies.querySelectorAll(`input[name="funding_body_ids[]"][value="${fundingBodyId}"]`).length > 0) {
    return;
  }

  // @ts-expect-error global variable
  const fundingBodyRow = window.$fbRowTemplate.replace('{{label}}', fundingBodyName).replace(/{{id}}/g, fundingBodyId);

  fundingBodies.insertAdjacentHTML('beforeend', fundingBodyRow);

  fundingBodySelect.value = '';
  fundingBodySelect.dispatchEvent(new Event('change'));
};

const deleteFundingBody = (event: Event) => {
  const target = event.target as HTMLLinkElement;
  const fundingBody = target.parentElement;
  if (!fundingBody) {
    return;
  }

  const grants = fundingBody.querySelectorAll<HTMLSpanElement>(
    'input[name^="collection[grants_attributes]"][name$="[_destroy]"]',
  );
  grants.forEach((grant) => {
    grant.checked = true;
  });

  fundingBody.classList.add('hidden');

  event.preventDefault();
};

const addGrant = (event: Event) => {
  const target = event.target as HTMLLinkElement;
  const fundingBody = target.parentElement;
  if (!fundingBody) {
    return;
  }

  const grantIdInput = fundingBody.querySelector<HTMLInputElement>('input[name="add_grant_id"]');
  if (!grantIdInput) {
    console.error('Grant ID input not found');
    return;
  }
  const grantId = grantIdInput.value;

  const fundingBodyIdInput = fundingBody.parentElement?.querySelector<HTMLInputElement>(
    'input[name="funding_body_ids[]"]',
  );
  if (!fundingBodyIdInput) {
    console.error('Funding body input not found');
    return;
  }
  const fundingBodyId = fundingBodyIdInput.value;

  const newId = new Date().getTime();

  if (!/^[a-zA-Z][a-zA-Z0-9_]+/.test(grantId)) {
    alert('grant id must start with a letter and only contain letters, numbers and underscores');
    return;
  }

  if (fundingBody.querySelectorAll(`#${grantId}`).length !== 0) {
    alert('grant id already exists');
    return;
  }

  // @ts-expect-error global variable
  const row = window.$giRowTemplate
    .replace(/{{grant_id}}/gm, grantId)
    .replace(/{{fb_id}}/gm, fundingBodyId)
    .replace(/{{uuid}}/g, newId);
  fundingBody.insertAdjacentHTML('beforeend', row);

  grantIdInput.value = '';

  event.preventDefault();
};

const removeNewGrant = (event: Event) => {
  const target = event.target as HTMLLinkElement;
  const grant = target.parentElement;
  if (!grant) {
    return;
  }

  grant.remove();

  event.preventDefault();
};

document.body.addEventListener('click', (event: Event) => {
  if (!event.target) {
    return;
  }

  if (!(event.target instanceof Element)) {
    return;
  }

  if (event.target.matches('.delete-funding-body')) {
    deleteFundingBody(event);
    return;
  }

  if (event.target.matches('.add-grant-id')) {
    addGrant(event);
    return;
  }

  if (event.target.matches('.delete-grant-id')) {
    removeNewGrant(event);
    return;
  }
});
