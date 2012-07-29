$ ->
  $(".select2").each ->
    options = {}
    if $(this).data('required')
      options['allowClear'] = false
    else
      options['allowClear'] = true
    options['placeholder'] = $(this).data('placeholder')

    if $(this).data('multiple')
      options['multiple'] = true
      val = $(this).val()
      val = val.replace(/[\]\[]/g, '')
      $(this).val(val)

    if $(this).data('url')
      extra_name = $(this).data('extra-name')
      extra_selector = $(this).data('extra-selector')
      url = $(this).data('url')
      options['ajax'] = {
        url: url,
        dataType: 'json',
        data: (term, page) ->
          params = { q: term, page: page }
          if extra_name
            params[extra_name] = $(extra_selector).val()
          params
        results: (data, page) ->
          data = ({id: d.id, text: d.name +  " (" + d.code + ")"} for d in data)
          {results: data}
      }
      options['initSelection'] = (element, callback) ->
        results = []
        ids = $(element).val().split(/,/)
        for id in ids
          data = {}
          $.ajax(
            url: url + '/' + id,
            dataType: 'json',
            async: false,
            success: (object) ->
              data = object
          )
          results.push { id: data.id, text: data.name + " (" + data.code + ")" }
        callback.call(null, results)

    $(this).select2(options)
