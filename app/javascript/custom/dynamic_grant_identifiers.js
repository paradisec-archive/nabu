const addFundingBody = (event) => { // eslint-disable-line no-unused-vars
  const fbid = event.target.value;
  const fbname = event.target.selectedOptions[0].label;
  if (fbid.length == 0) {
    return;
  }

  if ($('#funding-bodies').find('input[name="funding_body_ids[]"][value="'+fbid+'"]').length > 0) {
    return;
  }

  const $fbRow = window.$fbRowTemplate.replace('{{label}}', fbname).replace(/{{id}}/g, fbid);
  $('#funding-bodies').append($fbRow);
};

const removeChildGrantIds = (event) => { // eslint-disable-line no-unused-vars
  const $parent = $(event.target).parent();

  const $childGrantContainer = $parent.find('span.grant-fields')[0];

  // const $childGrants = $($childGrantContainer).find('div.grant-id');

  if ($($childGrantContainer).find('input[name="collection[grants_attributes][][id]"]').length > 0) {
    $($childGrantContainer).find('input[name="collection[grants_attributes][][id]"]').each(() => {
      const $gidInput = $(this).clone();
      $gidInput.prop('type', 'hidden');
      const $gidDestroy = $gidInput.clone();
      $gidDestroy.prop("name", $gidDestroy.attr("name").replace('id', '_destroy')).val('1');

      $('#funding-bodies-to-delete').append($gidInput).append($gidDestroy);
    });
  }
  $parent.remove();
};

const addGrantId = (event) => { // eslint-disable-line no-unused-vars
  const $parent = $(event.target).parent();
  const gid = $parent.find('input[name="add_grant_id"]').val();
  const fb_id = $parent.parent().find('input[name="funding_body_ids[]"]').val();
  if (/[a-zA-Z0-9_]+/.test(gid) && $parent.find('#'+gid).length == 0) {
    const $giRow = window.$giRowTemplate.replace(/{{grant_id}}/gm, gid).replace(/{{fb_id}}/gm, fb_id);
    $parent.append($giRow);
    $parent.find('input[name="add_grant_id"]').val('');
  }
};

const deleteGrantId = (event) => { // eslint-disable-line no-unused-vars
  const $parent = $(event.target).parent();
  if ($parent.find('input[name="collection[grants_attributes][][id]"]').length > 0) {
    const $gidInput = $parent.find('input[name="collection[grants_attributes][][id]"]').clone();
    $gidInput.prop('type', 'hidden');
    const $gidDestroy = $gidInput.clone();
    $gidDestroy.prop("name", $gidDestroy.attr("name").replace('id', '_destroy')).val('1');
    $('#funding-bodies-to-delete').append($gidInput).append($gidDestroy);
  }
  $parent.remove();
};
