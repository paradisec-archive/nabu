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
    data = options.merge({
      'ajax--url': users_path
    })

    class_name = options.delete 'class'
    users = User.where(id: params[attribute.to_s.sub('[]', '')])

    data[:data] = users.map { |user| { id: user.id, text: user.display_label, selected: true } }

    select_tag attribute, params[attribute], data:, class: "#{class_name} select2", multiple: options[:multiple]
  end

  def country_select_tag(attribute, options = {})
    data = options.merge({
      'ajax--url': countries_path,
      placeholder: 'Choose a country...',
      multiple: true
    })
    class_name = options.delete 'class'
    countries = Country.where(id: params[attribute.to_s.sub('[]', '')])
    data[:data] = countries.map { |country| { id: country.id, text: country.name, selected: true } }

    select_tag attribute, params[attribute], data:, class: "#{class_name} select2 country", multiple: true
  end

  def language_select_tag(attribute, options = {})
    data = options.merge({
      'ajax--url': languages_path,
      placeholder: 'Choose a language...',
      multiple: true,
      'extra-name': 'country_ids',
      'extra-selector': '#collection_country_ids'
    })
    class_name = options.delete 'class'
    languages = Language.where(id: params[attribute.to_s.sub('[]', '')])
    data[:data] = languages.map { |language| { id: language.id, text: language.name, selected: true } }

    select_tag attribute, params[attribute], data:, class: "#{class_name} select2 language", multiple: true
  end

  def mimetype_select_tag(attribute, options = {})
    data = options.merge({
      'ajax--url': list_mimetypes_path,
      placeholder: 'Choose a mimetype...'
    })

    class_name = options.delete 'class'
    data[:data] = Essence.where(mimetype: params[attribute]).pluck(:mimetype).map { |m| { id: m, text: m } }

    select_tag attribute, params[attribute], data:, class: "#{class_name} select2", multiple: options[:multiple]
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

  private

  def crawler_ip?
    crawler_subnet = IPAddr.new('202.46.62.0/24')
    crawler_subnet.include?(request.remote_ip)
  rescue IPAddr::InvalidAddressError
    false
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
end
