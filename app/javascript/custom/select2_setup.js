import select2 from 'select2';
// NOTE: It's not autoloading into jquery for some reason
select2(window.$);

export const setup_select2 = (element) => {
  const options = {
    allowClear: !$(element).data('required'),
  };

  const extra_name = $(element).data('extra-name');
  const extra_selector = $(element).data('extra-selector');
  if (extra_name && extra_selector) {
    const url = $(element).data('ajax--url');
    options.ajax = {
      url: url,
      data: (params) => {
        return {
          ...params,
          [extra_name]: $(extra_selector).val(),
        };
      },
    };
  }

  const tags = $(element).data('tags');
  if (tags) {
    options.tags = true;
    options.createTag = (params) => {
      const term = params.term.trim();

      if (term === '') {
        return null;
      }

      return {
        id: `NEWCONTACT:${term}`,
        text: term,
        newTag: true, // add additional parameters
      };
    };
  }

  $(element).select2(options);
};
