$ ->

  $('#add-university').click ->
    input = $('<div id="add-university-form"><input name="university[name]" id="university_name"><button>Add</button></div>')
    $(this).replaceWith input

    $('#add-university-form button').click ->
      console.log 'moo'
      value = $('#university_name').val()
      $.post '/universities', 'university[name]=' + value, (data) ->
        $('#collection_university_id').append($('<option></option>').attr('selected', 'selected').attr('value', data['id']).text(data['name']))
        $('#add-university-form').remove()
      .error ->
        $('#add-university-form').replaceWith('<p class="error">University already exists please select it from the drop down');
      return false

    return false

