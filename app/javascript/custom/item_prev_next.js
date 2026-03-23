const getCurrentIdentifier = () => {
  const match = window.location.pathname.match(/^\/collections\/([^/]+)\/items\/(.*)$/);
  if (!match) {
    return null;
  }

  const [_, collection, item] = match;

  return `${collection}-${item}`;
};

const noSearchUpdate = () => {
  document.querySelectorAll('.next_prev_button').forEach((button) => {
    const identifier = button.dataset.identifier;
    if (!identifier) {
      button.style.display = 'none';
      return;
    }

    const [collection, item] = identifier.split('-');
    button.href = `/collections/${collection}/items/${item}`;
  });
};

const currentIdentifier = getCurrentIdentifier();

if (currentIdentifier) {
  const resultIds = JSON.parse(sessionStorage.getItem('item_result_ids'));
  if (!resultIds) {
    const resultsButton = document.getElementById('results_button');
    if (resultsButton) resultsButton.style.display = 'none';
    noSearchUpdate();
  } else {
    const currentIndex = resultIds.indexOf(currentIdentifier);
    if (currentIndex < 0) {
      sessionStorage.removeItem('item_result_ids');
      noSearchUpdate();
    } else {
      const prevButton = document.getElementById('prev_button');
      const nextButton = document.getElementById('next_button');

      if (currentIndex > 0) {
        const identifier = resultIds[currentIndex - 1];
        const [collection, item] = identifier.split('-');
        if (prevButton) prevButton.href = `/collections/${collection}/items/${item}`;
      } else {
        if (prevButton) prevButton.style.display = 'none';
      }

      if (currentIndex < resultIds.length - 1) {
        const identifier = resultIds[currentIndex + 1];
        const [collection, item] = identifier.split('-');
        if (nextButton) nextButton.href = `/collections/${collection}/items/${item}`;
      } else {
        if (nextButton) nextButton.style.display = 'none';
      }
    }
  }
}
