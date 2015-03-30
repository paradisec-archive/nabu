$ ->
  # Add more fields to form
  $('form').on 'click', '.add_fields', (event) ->
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $(this).before($(this).data('fields').replace(regexp, time))
    setup_select2($(this).prev().prev());
    setup_select2($(this).prev());
    event.preventDefault()


  # Set up select2 elements
  $(".select2").each ->
    setup_select2(this)

  # Fix _ids hidden fields for select2
  $('form').submit ->
    form = $(this)
    form.find('input[type=hidden].select2').each ->
      if $(this).attr('name').match(/_ids]$/) and $(this).val() != ''
        ids = $(this).val().split(/,/)
        for id in ids
          form.append($('<input type=hidden name="' + $(this).attr('name') + '[]" value="' + id + '" />'))
          $(this).remove()
