class PageController < ApplicationController
  def index
  end

  def dashboard
    @num_collections = Collection.count
    @num_items = Item.count
    @num_essences = Essence.count
    @num_users = User.count
    @num_universities = University.count
    @num_comments = Comment.count

    @comments = Comment.order('id desc').limit(5)
  end
end
