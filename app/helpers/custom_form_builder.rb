# NOTE: You need to resart the server if you change this file
class CustomFormBuilder < ActionView::Helpers::FormBuilder
  def user_select(attribute, options = {})
    html_data = {
      'search-url': @template.users_path,
      placeholder: options[:placeholder] || 'Choose a user...'
    }
    html_data[:required] = true if options[:required]
    html_data[:tags] = true if options[:tags]

    select_options = {}
    select_options[:multiple] = options[:multiple] if options[:multiple]

    class_name = options.delete 'class'
    users = @object.send(attribute.to_s.sub('_id', '').to_sym)
    users = [users] if users.is_a? User
    users = [] if users.nil?

    option_pairs = users.map { |user| [user.display_label, user.id] }

    select(attribute, option_pairs, select_options, { data: html_data, class: "#{class_name} choices-select" })
  end

  def data_category_select(attribute, options = {})
    html_data = {
      placeholder: options[:placeholder] || 'Choose a category...'
    }

    select_options = {}
    select_options[:multiple] = options[:multiple] if options[:multiple]

    class_name = options.delete 'class'
    selected_ids = @object.send(attribute.to_s.sub('y_ids', 'ies').to_sym).map(&:id)

    all_categories = DataCategory.order(:name).map { |dc| [dc.name, dc.id] }

    select(attribute, @template.options_for_select(all_categories, selected_ids), select_options, { data: html_data, class: "#{class_name} choices-select" })
  end

  def data_type_select(attribute, options = {})
    html_data = {
      placeholder: options[:placeholder] || 'Choose a type...'
    }

    select_options = {}
    select_options[:multiple] = options[:multiple] if options[:multiple]

    class_name = options.delete 'class'
    selected_ids = @object.send(attribute.to_s.sub('_ids', 's').to_sym).map(&:id)

    all_types = DataType.order(:name).map { |dt| [dt.name, dt.id] }

    select(attribute, @template.options_for_select(all_types, selected_ids), select_options, { data: html_data, class: "#{class_name} choices-select" })
  end

  def country_select(attribute, options = {})
    html_data = {
      placeholder: 'Choose a country...'
    }
    class_name = options.delete 'class'
    selected_ids = @object.countries.map(&:id)

    all_countries = Country.order(:name).map { |c| [c.name, c.id] }

    select(attribute, @template.options_for_select(all_countries, selected_ids), { multiple: true }, { data: html_data, class: "#{class_name} choices-select country" })
  end

  def language_select(attribute, options = {})
    html_data = {
      'search-url': @template.languages_path,
      placeholder: 'Choose a language...',
      'extra-name': 'country_ids',
      'extra-selector': '#collection_country_ids'
    }
    class_name = options.delete 'class'
    languages = @object.send(attribute.to_s.sub('_id', '').to_sym)

    option_pairs = languages.map { |language| [language.name, language.id] }

    select(attribute, option_pairs, { multiple: true }, { data: html_data, class: "#{class_name} choices-select language" })
  end

  def university_select(attribute, options = {})
    preloaded_select(attribute, University.alpha, :name, options.reverse_merge(placeholder: 'Choose a university...'), css_class: 'university')
  end

  def access_condition_select(attribute, options = {})
    preloaded_select(attribute, AccessCondition.alpha, :name, options.reverse_merge(placeholder: 'Choose a data access condition...'))
  end

  def discourse_type_select(attribute, options = {})
    preloaded_select(attribute, DiscourseType.alpha, :name, options.reverse_merge(placeholder: 'Choose a discourse...'))
  end

  def field_of_research_select(attribute, options = {})
    preloaded_select(attribute, FieldOfResearch.alpha, :name_with_identifier, options.reverse_merge(placeholder: 'Choose a field of research...'))
  end

  def funding_body_select(options = {})
    html_data = {
      placeholder: options[:placeholder] || 'Choose a funding body...',
      'change-action': 'funding-body'
    }

    all_bodies = FundingBody.alpha.map { |f| [f.name, f.id] }

    @template.select_tag 'funding_body_select', @template.options_for_select(all_bodies), id: 'funding_body_select', class: 'choices-select', include_blank: true, data: html_data
  end

  private

  def preloaded_select(attribute, collection, label_method, options = {}, css_class: nil)
    html_data = {
      placeholder: options[:placeholder]
    }

    all_items = collection.map { |item| [item.send(label_method), item.id] }
    selected_id = @object.send(attribute)

    classes = ['choices-select', css_class].compact.join(' ')

    select(attribute, @template.options_for_select(all_items, selected_id), { include_blank: true }, { data: html_data, class: classes })
  end
end
