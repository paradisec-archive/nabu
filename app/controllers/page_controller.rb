class PageController < ApplicationController
  def home
    @coordinates = Collection.all.map(&:center_coordinate).compact
    @content = render_to_string :partial => 'page/infowindow'
  end

  def dashboard
    @name = current_user.name

    collections = Collection.where("collector_id = ? OR operator_id = ?", current_user.id, current_user.id)
    collections &&= Collection.joins(:collection_admins).where("collection_admins.user_id = ? ", 2)
    if (params[:sort])
      collections = collections.order(params[:sort] + ' ' + params[:direction])
    else
      collections = collections.order('created_at desc')
    end
    @num_collections = collections.count
    @collections = collections.page(params[:collections_page]).per(params[:collections_per_page])

    items = Item.where(:collector_id => current_user).order(:updated_at)
    @num_items = items.count
    @items = items.page(params[:items_page]).per(params[:items_per_page])

    @comments = Comment.owned_by(current_user)
    @num_comments = @comments.count

    @comments_left = Item.where(:collector_id => current_user).map(&:comments).flatten
    @num_comments_left = @comments_left.count

    @coordinates = @collections.map(&:center_coordinate).compact
    @north_limit = @coordinates.map{|c| c[:lat]}.max
    @south_limit = @coordinates.map{|c| c[:lat]}.min
    @east_limit  = @coordinates.map{|c| c[:lng]}.max
    @west_limit  = @coordinates.map{|c| c[:lng]}.min
    @content = render_to_string :partial => 'page/infowindow'
  end

  def glossary
    @universities = University.all
    @fundingBodies = FundingBody.all
  end
end
