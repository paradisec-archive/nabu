$(() => {
  const datePickerOptions = {
    dateFormat: 'dd MM yy',
    buttonImageOnly: true,
    buttonImage: calendarImagePath,
    showOn: 'both',
    changeMonth: true,
    changeYear: true,
    yearRange: 'c-40:c+1',
  };

  $('.dateinput').datepicker(datePickerOptions);
});
