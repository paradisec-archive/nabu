class PageController < ApplicationController
  def home
    @page_title = 'Nabu - Home'
    item_counts = Item.group(:collection_id).count
    @coordinates = Collection.where(private: false).map { |c| c.center_coordinate(item_counts) }.compact
    @content = render_to_string partial: 'page/infowindow'
  end

  def dashboard
    authenticate_user!

    @page_title = 'Nabu - Dashboard'
    @name = current_user.name

    collections = Collection.where('collector_id = :user_id OR operator_id = :user_id', user_id: current_user.id)
    collections = if params[:sort]
                    collections.order("#{params[:sort]} #{params[:direction]}")
                  else
                    collections.order('created_at desc')
                  end
    @num_collections = collections.count
    @collections = collections.page(params[:collections_page]).per(params[:collections_per_page])

    items = Item.includes(:collection).where(collector_id: current_user).order(:updated_at)
    @num_items = items.count
    @items = items.page(params[:items_page]).per(params[:items_per_page])

    @comments = Comment.owned_by(current_user)
    @num_comments = @comments.count

    @comments_left = Item.includes(:comments).where(collector_id: current_user).map(&:comments).flatten
    @num_comments_left = @comments_left.count

    item_counts = Item.group(:collection_id).count
    @coordinates = @collections.map { |c| c.center_coordinate(item_counts) }.compact
    @north_limit = @coordinates.pluck(:lat).max
    @south_limit = @coordinates.pluck(:lat).min
    @east_limit  = @coordinates.pluck(:lng).max
    @west_limit  = @coordinates.pluck(:lng).min
    @content = render_to_string partial: 'page/infowindow'
  end

  def glossary
    @page_title = 'Nabu - Glossary'
    @universities = University.all
    @funding_bodies = FundingBody.all
  end

  def apidoc
    @page_title = 'Nabu - API Documentation'
  end

  def contact
    @page_title = 'Nabu - Contact'
  end
end
