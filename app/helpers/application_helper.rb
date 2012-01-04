module ApplicationHelper
  def admin_user_signed_in?
    user_signed_in? and current_user.admin?
  end

#  def sortable(column, title = nil)
#    title ||= column.titleize
#    direction = (column == params[:sort] && params[:direction] == "asc") ? "desc" : "asc"
#    html = link_to title, params.merge(:sort => column, :direction => direction), {:class => 'sortable'}
#    icon = 'ui-icon-triangle-2-n-s'
#    if column == params[:sort]
#      icon = params[:direction] == 'desc' ? 'ui-icon-triangle-1-s' : 'ui-icon-triangle-1-n'
#    end
#
#    html += content_tag :span, nil, :class => "ui-icon #{icon}"
#  end

  def sortable(field, title = nil)
    field = field.to_s
    title ||= field.titleize

    css_class = "sortable" + ((field == params[:sort]) ? " current #{params[:direction]}" : '')
    direction = (field == params[:sort] && params[:direction] == "asc") ? "desc" : "asc"
    content_tag :th, :class => css_class, :data => {:direction => direction, :field => field} do
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
    "%02d:%02d:%02d.%d" % [hh, mm, ss, ms * 1000]
  end
end
