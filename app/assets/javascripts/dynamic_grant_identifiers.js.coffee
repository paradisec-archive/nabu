@addFundingBody = (event)->
  fbid = event.target.value
  fbname = event.target.selectedOptions[0].label
  return if $('#funding-bodies').find('input[name="funding_body_ids[]"][value="'+fbid+'"]').length > 0
  $fbRow = $fbRowTemplate.replace('{{label}}', fbname).replace(/{{id}}/g, fbid)
  $('#funding-bodies').append($fbRow)

@addGrantId = (event)->
  $parent = $(event.target).parent()
  gid = $parent.find('input[name="add_grant_id"]').val()
  fb_id = $parent.parent().find('input[name="funding_body_ids[]"]').val()
  if /[a-zA-Z0-9_]+/.test(gid) and $parent.find('#'+gid).length == 0
    $giRow = $giRowTemplate.replace(/{{grant_id}}/gm, gid).replace(/{{fb_id}}/gm, fb_id)
    $parent.append($giRow);

@deleteGrantId = (event)->
  $parent = $(event.target).parent()
  if $parent.find('input[name="collection[grants_attributes][][id]"]').length > 0
    $gidInput = $parent.find('input[name="collection[grants_attributes][][id]"]').clone()
    $gidInput.prop('type', 'hidden')
    $gidDestroy = $gidInput.clone()
    $gidDestroy.prop("name", $gidDestroy.attr("name").replace('id', '_destroy')).val('1')
    $('#funding-bodies-to-delete').append($gidInput).append($gidDestroy)
  $parent.remove();