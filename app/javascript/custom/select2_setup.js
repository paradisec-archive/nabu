export const setup_select2 = (element, noinit=false) => { // eslint-disable-line no-unused-vars
  const options = {};

  if ($(element).data('required')) {
    options['allowClear'] = false;
  } else {
    options['allowClear'] = true;
  }

  options['placeholder'] = $(element).data('placeholder');

  if ($(element).data('multiple')) {
    options['multiple'] = true;
    let val = $(element).val();
    val = val.replace(/ /g, ',');
    $(element).val(val);
  }

  if ($(element).data('url')) {
    const extra_name = $(element).data('extra-name');
    const extra_selector = $(element).data('extra-selector');
    const url = $(element).data('url');
    options['ajax'] = {
      url: url,
      dataType: 'json',
      delay: 250,
      data: (term, page) => {
        const params = { q: term, page: page }
        if (extra_name) {
          params[extra_name] = $(extra_selector).val();
        }
        return params;
      },
      results: (data) => {
        const results = [];
        data.forEach((d) => {
          let text = d.name;
          if (d.code) {
            text = text + " (" + d.code + ")";
          }
          results.push({ id: d.id, text: text });
        });

        return { results };
      }
    }

    if (noinit) {
      options['initSelection'] = (element, callback) => {
        callback.call(null, {id: $(element).val(), text: $(element).val()})
      };
    } else {
      options['initSelection'] = (element, callback) => {
        let results = [];
        const ids = $(element).val().split(/, ?/);
        ids.forEach((id) => {
          let data = {};
          $.ajax({
            url: url + '/' + id,
            dataType: 'json',
            async: false,
            success: (object) => {
              data = object;
            }
          });
          let text = data.name;
          if (data.code) {
            text = text + " (" + data.code + ")";
          }
          if (options['multiple']) {
            results.push({ id: data.id, text: text });
          } else {
            results = { id: data.id, text: text };
          }
        });

        callback.call(null, results);
      };
    }
  }

  const createable = $(element).data('createable')
  if (createable) {
    options['createSearchChoice'] = (term) => {
      return {id: 'NEWCONTACT:'+term, text: term};
    }
  }

  const data = $(element).data('data');
  if (data) {
    options['data'] = data;
  }

  $(element).select2(options);
};
