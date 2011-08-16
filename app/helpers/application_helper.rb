module ApplicationHelper
  def admin_user_signed_in?
    user_signed_in? and current_user.admin?
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    direction = (column == params[:sort] && params[:direction] == "asc") ? "desc" : "asc"
    html = link_to title, {:sort => column, :direction => direction}, {:class => 'sortable'}
    icon = 'ui-icon-triangle-2-n-s'
    if column == params[:sort]
      icon = params[:direction] == 'desc' ? 'ui-icon-triangle-1-s' : 'ui-icon-triangle-1-n'
    end

    html += content_tag :span, nil, :class => "ui-icon #{icon}"
  end

end
