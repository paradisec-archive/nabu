module ApplicationHelper
  def admin_user_signed_in?
    user_signed_in? and current_user.admin?
  end

  def sortable(field, title = nil)
    field = field.to_s
    title ||= field.titleize

    css_class = 'sortable' + ((field == params[:sort]) ? " current #{params[:direction]}" : '')
    direction = (field == params[:sort] && params[:direction] == 'asc') ? 'desc' : 'asc'
    content_tag :th, class: css_class, data: { direction: direction, field: field } do
      title
    end
  end

  def number_to_human_rate(bits)
    return nil if bits.nil?

    number_to_human_size(bits).gsub(/Bytes/, 'bps')
  end

  def number_to_human_channels(channels)
   case channels
   when 1 then 'Mono'
   when 2 then 'Stereo'
   else nil
   end
  end

  def number_to_human_duration(t)
    return nil if t.nil?
    ms = t - t.to_i
    mm, ss = t.divmod(60)
    hh, mm = mm.divmod(60)
    '%02d:%02d:%02d.%d' % [hh, mm, ss, ms * 1000]
  end

  def current_link_to(label, path, cname)
    if controller.controller_name == 'page'
      link_to label, path, ({ class: 'active' } if cname == controller.controller_name + '#' + controller.action_name)
    else
      link_to label, path, ({ class: 'active' } if cname == controller.controller_name)
    end
  end

  def admin_messages
    now = DateTime.now
    AdminMessage.where('start_at <= ?', now).where('finish_at >= ?', now)
  end

  def user_select_tag(attribute, options = {})
    html_data = {
      'search-url': users_path,
      placeholder: options[:placeholder] || 'Choose a user...'
    }

    class_name = options.delete 'class'
    users = User.where(id: params[attribute.to_s.sub('[]', '')])
    option_tags = options_for_select(users.map { |user| [user.display_label, user.id] })

    select_tag attribute, option_tags, data: html_data, class: "#{class_name} choices-select", multiple: options[:multiple]
  end

  def country_select_tag(attribute, options = {})
    html_data = {
      placeholder: 'Choose a country...'
    }
    class_name = options.delete 'class'
    selected_ids = params[attribute.to_s.sub('[]', '')]

    all_countries = Country.order(:name).map { |c| [c.name, c.id] }
    option_tags = options_for_select(all_countries, selected_ids)

    select_tag attribute, option_tags, data: html_data, class: "#{class_name} choices-select country", multiple: true
  end

  def language_select_tag(attribute, options = {})
    html_data = {
      'search-url': languages_path,
      placeholder: 'Choose a language...',
      'extra-name': options[:'extra-name'] || 'country_ids',
      'extra-selector': options[:'extra-selector'] || '#collection_country_ids'
    }
    class_name = options.delete 'class'
    languages = Language.where(id: params[attribute.to_s.sub('[]', '')])
    option_tags = options_for_select(languages.map { |language| [language.name, language.id] })

    select_tag attribute, option_tags, data: html_data, class: "#{class_name} choices-select language", multiple: true
  end

  def mimetype_select_tag(attribute, options = {})
    html_data = {
      placeholder: 'Choose a mimetype...'
    }

    class_name = options.delete 'class'
    all_mimetypes = Essence.distinct.pluck(:mimetype).compact.sort.map { |m| [m, m] }
    selected = params[attribute]
    option_tags = options_for_select(all_mimetypes, selected)

    select_tag attribute, option_tags, data: html_data, class: "#{class_name} choices-select", multiple: options[:multiple]
  end

  def university_select_tag(attribute, options = {})
    preloaded_select_tag(attribute, University.alpha, :name, 'Choose a university...', options)
  end

  def access_condition_select_tag(attribute, options = {})
    preloaded_select_tag(attribute, AccessCondition.alpha, :name, 'Choose a data access condition...', options)
  end

  def discourse_type_select_tag(attribute, options = {})
    preloaded_select_tag(attribute, DiscourseType.alpha, :name, 'Choose a discourse...', options)
  end

  def field_of_research_select_tag(attribute, options = {})
    preloaded_select_tag(attribute, FieldOfResearch.alpha, :name_with_identifier, 'Choose a field of research...', options)
  end

  def funding_body_select_tag(attribute, options = {})
    preloaded_select_tag(attribute, FundingBody.alpha, :name, 'Choose a funding body...', options)
  end

  def data_category_select_tag(attribute, options = {})
    preloaded_select_tag(attribute, DataCategory.order(:name), :name, 'Choose a category...', options, multiple: true)
  end

  def data_type_select_tag(attribute, options = {})
    preloaded_select_tag(attribute, DataType.order(:name), :name, 'Choose a type...', options, multiple: true)
  end

  def crawler_request?
    return true if crawler_ip?
    return false unless request.user_agent.present?

    crawler_patterns = [
      /bot/i,
      /crawler/i,
      /spider/i,
      /scraper/i,
      /facebookexternalhit/i,
      /twitterbot/i,
      /linkedinbot/i,
      /whatsapp/i,
      /telegram/i,
      /slackbot/i,
      /googlebot/i,
      /bingbot/i,
      /yandexbot/i,
      /duckduckbot/i,
      /baiduspider/i,
      /applebot/i,
      /semrushbot/i,
      /ahrefsbot/i,
      /dotbot/i,
      /mj12bot/i,
      /blexbot/i,
      /petalbot/i
    ]

    crawler_patterns.any? { |pattern| request.user_agent.match?(pattern) }
  end

  def oni_collection_url(collection)
    "#{Rails.application.config.oni_url}/collection?id=#{URI.encode_www_form_component(repository_collection_url(collection))}"
  end

  def oni_item_url(item)
    "#{Rails.application.config.oni_url}/object?id=#{URI.encode_www_form_component(repository_item_url(item.collection, item))}"
  end

  def oni_essence_url(essence)
    "#{Rails.application.config.oni_url}/file?id=#{URI.encode_www_form_component(repository_essence_url(essence.collection, essence.item, essence.filename))}"
  end

  private

  def preloaded_select_tag(attribute, collection, label_method, default_placeholder, options = {}, multiple: false)
    html_data = {
      placeholder: options[:placeholder] || default_placeholder
    }

    all_items = collection.map { |item| [item.send(label_method), item.id] }
    param_key = multiple ? attribute.to_s.sub('[]', '') : attribute
    selected = params[param_key]
    option_tags = options_for_select(all_items, selected)

    tag_options = { data: html_data, class: 'choices-select' }
    tag_options[:include_blank] = true unless multiple
    tag_options[:multiple] = true if multiple

    select_tag attribute, option_tags, **tag_options
  end

  def crawler_ip?
    crawler_subnet = IPAddr.new('202.46.62.0/24')
    crawler_subnet.include?(request.remote_ip)
  rescue IPAddr::InvalidAddressError
    false
  end
end
