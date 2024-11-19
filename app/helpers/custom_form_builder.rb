# NOTE: You need to resart the server if you change this file
class CustomFormBuilder < ActionView::Helpers::FormBuilder
  def user_select(attribute, options = {})
    data = options.merge({
      'ajax--url': @template.users_path
    })

    select_options = {}
    select_options[:multiple] = options[:multiple] if options[:multiple]

    class_name = options.delete 'class'
    users = @object.send(attribute.to_s.sub('_id', '').to_sym)
    users = [users] if users.is_a? User
    users = [] if users.nil?

    data[:data] = users.map { |user| { id: user.id, text: user.display_label, selected: true } }

    select(attribute, [], select_options, { data:, class: "#{class_name} select2" })
  end

  def country_select(attribute, options = {})
    data = options.merge({
      'ajax--url': @template.countries_path,
      placeholder: 'Choose a country...',
      multiple: true
    })
    class_name = options.delete 'class'
    countries = @object.countries
    data[:data] = countries.map { |country| { id: country.id, text: country.name, selected: true } }

    select(attribute, [], { multiple: true }, { data:, class: "#{class_name} select2 country" })
  end

  def language_select(attribute, options = {})
    data = options.merge({
      'ajax--url': @template.languages_path,
      placeholder: 'Choose a language...',
      multiple: true,
      'extra-name': 'country_ids',
      'extra-selector': '#collection_country_ids'
    })
    class_name = options.delete 'class'
    languages = @object.send(attribute.to_s.sub('_id', '').to_sym)
    data[:data] = languages.map { |language| { id: language.id, text: language.name, selected: true } }

    select(attribute, [], { multiple: true }, { data:, class: "#{class_name} select2 language" })
  end
end
