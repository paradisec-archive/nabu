$ ->
  $('select.addable').each ->
    id = $(this).attr('id')
    $(this).parent().append('<a class="adder" href="#" data-id="' + id + '"> Add </a>')

  $('a.adder').click ->
    id = $(this).data('id')
    list = $('#' + id)
    list_id = list.attr('id')
    list_name = list.attr('name')
    list_num = parseInt(list_id.replace(/.*(\d+).*/, "$1"))
    new_list = list.clone()
    new_list.attr('id', list_id.replace(/\d+/, list_num + 1))
    new_list.attr('name', list_name.replace(/\d+/, list_num + 1))
    $(this).parent().prepend(new_list).prepend('<br/>')
    $(this).data('id', new_list.attr('id'))

    return false;


