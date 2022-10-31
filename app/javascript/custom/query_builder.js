var logicSelect = '<select name="clause[0][logic]"><option value="AND">AND</option><option value="OR">OR</option><option value="NOT">NOT</option></select>';
$(document).ready(function() {
    $('button.add:not(:last)').remove();
    var addButton = $('button.add:last').clone();
    $(document).on('click', 'button.remove', function() {
        if (this.name == 'clause[0]') return;
        var row = $('[id="'+this.name+'"]');
        var addButton = row.find('button.add');
        row.remove();
        if (addButton.length) {
            $('div.clause:last').append(addButton.clone());
        }
    });

    function replaceWithType(el, name, id) {
        var newInput;
        if (id) {
            newInput = $('#'+id).clone();
        } else {
            newInput = $('.input-templates > [name="'+name+'"]').clone();
        }
        newInput.attr('name', el.attr('name')).addClass('field-value');
        newInput.val(el.last().val());
        el.last().after(newInput);
        el.remove();
        return newInput;
    }

    function replaceWithTextInput(el) {
        return replaceWithType(el, 'text')
    }

    function replaceWithBooleanInput(el) {
        return replaceWithType(el, 'boolean');
    }

    function replaceWithDateInput(el) {
        var field = replaceWithType(el, 'date');
        field.attr('id', 'dateClause'+$(el).prop('name').replace(/\D/,''));
        $(field).datepicker(window.datePickerOptions)
        return field;
    }

    function replaceWithNumber(el) {
        return replaceWithType(el, 'number');
    }

    function replaceWithCollection(el, id) {
        var field = replaceWithType(el, null, id);
        setup_select2(field);
        return field;
    }

    function replaceWithAutocomplete(el, id) {
        var field = replaceWithType(el, 'autocomplete');
        var placeholderLabel = id.replace('_id', '').replace('_',' ').replace('s.id','')
                                 .replace(/ie$/,'y').replace('s.m', ' m');
        var useIdAsLabel = false;
        field.addClass('select2').data('placeholder', 'Choose a '+placeholderLabel+'...');
        switch (id) {
            case 'collector_id':
            case 'operator_id':
            case 'agents.id':
            case 'users.id':
            case 'admins.id':
                field.data('url', usersPath);
                break;
            case 'subject_languages.id':
            case 'content_languages.id':
                field.data('url', languagesPath);
                break;
            case 'countries.id':
                field.data('url', countriesPath);
                break;
            case 'data_categories.id':
                field.data('url', dataCategoriesPath);
                break;
            case 'data_types.id':
                field.data('url', dataTypesPath);
                break;
            case 'essences.mimetype':
                field.data('url', mimeTypesPath);
                useIdAsLabel = true;
                break;
        }
        setup_select2(field, useIdAsLabel);
        return field;
    }

    function replaceFieldByType(typeForField, fieldName, valueField) {
        switch (typeForField) {
            case 'boolean':
                return replaceWithBooleanInput(valueField);
                break;
            case 'number':
                return replaceWithNumber(valueField);
                break;
            case 'date':
                return replaceWithDateInput(valueField);
                break;
            case 'collection':
                return replaceWithCollection(valueField, fieldName);
                break;
            case 'autocomplete':
                return replaceWithAutocomplete(valueField, fieldName);
                break;
            case 'text':
            default:
                return replaceWithTextInput(valueField);
                break;
        }
    }
    $(document).on('change', '.operator', function() {
        $(this).closest('.clause').find('.field-value').attr('disabled', $(this).val().indexOf('null') !== -1);
    });

    $(document).on('change', '.field-name', function() {
        var fieldName = $(this).val();
        var typeForField = typesForFields[fieldName];
        var valueField = $(this).closest('.clause').find('.field-value');
        $(this).closest('.clause').find('.ui-datepicker-trigger').remove(); // remove any leftover datepicker stuff
        replaceFieldByType(typeForField, fieldName, valueField);
    });

    $(document).on('click', 'button.add', function() {
        var numRows = $('div.clause').length;
        var row = $('[id="clause[0]"]').clone();
        $('button.add').remove();
        row.attr('id', 'clause['+numRows+']');
        row.prepend($(logicSelect.replace('[0]', '['+numRows+']')));
        row.find('select,input,button').each(function() {
            this.name = this.name.replace('[0]', '['+numRows+']')
        });
        // clear existing vals
        row.find('input').val('');
        row.find('option').attr('selected', null);
        if (!row.find('button.add').length) row.append(addButton);

        $('.qb button.submit').before(row);

        var fieldName = $(row).find('.field-name').val();
        var typeForField = typesForFields[fieldName];
        replaceFieldByType(typeForField, fieldName, $(row).find('.field-value'));
    });

    // re-init the fields after page load
    $('.clause .field-value').each(function() {
        var fieldName = $(this).closest('.clause').find('.field-name').val();
        var operator = $(this).closest('.clause').find('.operator').val();
        var typeForField = typesForFields[fieldName];
        var field = replaceFieldByType(typeForField, fieldName, $(this));
        $(field).attr('disabled', operator.indexOf('null') !== -1);
        console.log(field, (operator.indexOf('null') !== -1));
    })
});
