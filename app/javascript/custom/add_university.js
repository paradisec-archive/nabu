$(() => {
  $('#add-university').on('click', function () {
    const input = $(
      '<div id="add-university-form"><input name="university[name]" id="university_name"><button>Add</button></div>',
    );
    $(this).replaceWith(input);

    $('#add-university-form button').on('click', () => {
      const value = $('#university_name').val();
      $.post('/universities', `university[name]=${value}`, (data) => {
        $('university').append(
          $('<option></option>').attr('selected', 'selected').attr('value', data.id).text(data.name),
        );
        $('university').trigger('change');
        $('#add-university-form').remove();
      }).error(() => {
        $('#add-university-form').replaceWith(
          '<p class="error">University already exists please select it from the drop down',
        );
      });
      return false;
    });

    return false;
  });
});
