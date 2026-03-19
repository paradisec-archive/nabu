import { getChoicesInstance } from './choices_setup';

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

  const fbRowTemplate = fundingBodies.dataset.fbRowTemplate;
  if (!fbRowTemplate) {
    throw new Error('Funding body row template not found');
  }
  const fundingBodyRow = fbRowTemplate.replace('{{label}}', fundingBodyName).replace(/{{id}}/g, fundingBodyId);

  fundingBodies.insertAdjacentHTML('beforeend', fundingBodyRow);

  const instance = getChoicesInstance(fundingBodySelect);
  if (instance) {
    instance.setChoiceByValue('');
  }
};

const deleteFundingBody = (event: Event) => {
  event.preventDefault();

  const target = event.target as HTMLLinkElement;
  const fundingBody = target.parentElement;
  if (!fundingBody) {
    return;
  }

  const grants = fundingBody.querySelectorAll<HTMLInputElement>('input[name^="collection[grants_attributes]"][name$="[_destroy]"]');
  grants.forEach((grant) => {
    grant.checked = true;
  });

  fundingBody.classList.add('hidden');
};

const addGrant = (event: Event) => {
  event.preventDefault();

  const target = event.target as HTMLLinkElement;
  const fundingBody = target.parentElement;
  if (!fundingBody) {
    return;
  }

  const grantIdInput = fundingBody.querySelector<HTMLInputElement>('input[name="add_grant_id"]');
  if (!grantIdInput) {
    throw new Error('Grant ID input not found');
  }
  const grantId = grantIdInput.value;

  const fundingBodyIdInput = fundingBody.parentElement?.querySelector<HTMLInputElement>('input[name="funding_body_ids[]"]');
  if (!fundingBodyIdInput) {
    throw new Error('Funding body ID input not found');
  }
  const fundingBodyId = fundingBodyIdInput.value;

  const newId = Date.now();

  if (!/^[a-zA-Z][a-zA-Z0-9_]+/.test(grantId)) {
    alert('grant id must start with a letter and only contain letters, numbers and underscores');

    return;
  }

  if (fundingBody.querySelectorAll(`#${grantId}`).length !== 0) {
    alert('grant id already exists');

    return;
  }

  const fundingBodies = document.getElementById('funding-bodies');
  const giRowTemplate = fundingBodies?.dataset.giRowTemplate;
  if (!giRowTemplate) {
    console.error('Grant identifier row template not found');
    return;
  }
  const row = giRowTemplate
    .replace(/{{grant_id}}/gm, grantId)
    .replace(/{{fb_id}}/gm, fundingBodyId)
    .replace(/{{uuid}}/g, String(newId));
  fundingBody.insertAdjacentHTML('beforeend', row);

  grantIdInput.value = '';
};

const removeNewGrant = (event: Event) => {
  event.preventDefault();

  const target = event.target as HTMLLinkElement;
  const grant = target.parentElement;
  if (!grant) {
    return;
  }

  grant.remove();
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
