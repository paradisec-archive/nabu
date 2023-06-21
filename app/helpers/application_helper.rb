require 'aws-sdk-s3'

module ApplicationHelper
  def admin_user_signed_in?
    user_signed_in? and current_user.admin?
  end

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

  def current_link_to label, path, cname
    if controller.controller_name == 'page'
      link_to label, path, ({:class => 'active'} if cname == controller.controller_name + "#" + controller.action_name)
    else
      link_to label, path, ({:class => 'active'} if cname == controller.controller_name)
    end
  end

  def admin_messages
    now = DateTime.now
    AdminMessage.where("start_at <= ?", now).where("finish_at >= ?", now)
  end

  def catalog_download(path)
    # NOTE: This is all hard coded but will be replace by OCFL soon so we don't care
    bucket = Rails.env.production? ? 'nabu-catalog-prod' : 'nabu-catalog-stage'

    s3 = Aws::S3::Resource.new(region: 'ap-southeast-2')

    obj = s3.bucket(bucket).object(path)

    filename = path.split('/').last

    obj.presigned_url(:get, expires_in: 3600, response_content_disposition: "attachment; filename=\"#{filename}\"")
  end

  def catalog_url(path)
    # NOTE: This is all hard coded but will be replace by OCFL soon so we don't care
    bucket = Rails.env.production? ? 'nabu-catalog-prod' : 'nabu-catalog-stage'

    s3 = Aws::S3::Resource.new(region: 'ap-southeast-2')

    obj = s3.bucket(bucket).object(path)

    obj.presigned_url(:get, expires_in: 3600)
  end
end
