const getCurrentIdentifier = () => {
  const match = window.location.pathname.match(/^\/collections\/([^\/]+)\/items\/(.*)$/);
  if (!match) {
    return null;
  }

  const [_, collection, item] = match;

  return `${collection}-${item}`;
};

const noSearchUpdate = () => {
  $('.next_prev_button').each((_i, button) => {
    const identifier = $(button).data('identifier');
    if (!identifier) {
      $(button).hide();

      return;
    }

    const [collection, item] = identifier.split('-');
    $(button).attr('href', `/collections/${collection}/items/${item}`);
  });
};

$(() => {
  const currentIdentifier = getCurrentIdentifier();

  if (!currentIdentifier) {
    return;
  }

  const resultIds = JSON.parse(sessionStorage.getItem('item_result_ids'));
  if (!resultIds) {
    $('#results_button').hide();
    noSearchUpdate();

    return;
  }

  const currentIndex = resultIds.indexOf(currentIdentifier);
  if (currentIndex < 0) {
    sessionStorage.removeItem('item_result_ids');
    noSearchUpdate();

    return;
  }

  if (currentIndex > 0) {
    const identifier = resultIds[currentIndex - 1];
    const [collection, item] = identifier.split('-');
    const url = `/collections/${collection}/items/${item}`;
    $('#prev_button').attr('href', url);
  } else {
    $('#prev_button').hide();
  }

  if (currentIndex < resultIds.length - 1) {
    const identifier = resultIds[currentIndex + 1];
    const [collection, item] = identifier.split('-');
    const url = `/collections/${collection}/items/${item}`;
    $('#next_button').attr('href', url);
  } else {
    $('prev_button').hide();
  }
});
