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
    title ||= field.to_s.titleize
    css_class = "sortable" + ((field == params[:sort]) ? " current #{params[:direction]}" : '')
    direction = (field == params[:sort] && params[:direction] == "asc") ? "desc" : "asc"
    content_tag :th, :class => css_class, :data => {:direction => direction, :field => field} do
      title
    end
  end
end
