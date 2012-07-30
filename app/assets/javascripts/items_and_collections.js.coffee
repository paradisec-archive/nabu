setup_select2 = (element) ->
    options = {}
    if $(element).data('required')
      options['allowClear'] = false
    else
      options['allowClear'] = true
    options['placeholder'] = $(element).data('placeholder')

    if $(element).data('multiple')
      options['multiple'] = true
      val = $(element).val()
      val = val.replace(/[\]\[]/g, '')
      $(element).val(val)

    if $(element).data('url')
      extra_name = $(element).data('extra-name')
      extra_selector = $(element).data('extra-selector')
      url = $(element).data('url')
      options['ajax'] = {
        url: url,
        dataType: 'json',
        data: (term, page) ->
          params = { q: term, page: page }
          if extra_name
            params[extra_name] = $(extra_selector).val()
          params
        results: (data, page) ->
          results = []
          for d in data
            text = d.name
            if d.code
              text = text + " (" + d.code + ")"
            results.push {id: d.id, text: text}
          {results: results}
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
          text = data.name
          if data.code
            text = text + " (" + data.code + ")"
          results.push { id: data.id, text: text }
        callback.call(null, results)

    createable = $(element).data('createable')
    if createable
      console.log("Setup Create");
      options['createSearchChoice'] = (term) ->
        return {id: 'NEWCONTACT:'+term, text: term}

    $(element).select2(options)

jQuery ->
  $('form').on 'click', '.add_fields', (event) ->
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $(this).before($(this).data('fields').replace(regexp, time))
    setup_select2($(this).prev().prev());
    setup_select2($(this).prev());
    event.preventDefault()

$ ->
  $(".select2").each ->
    setup_select2(this)
