class PageController < ApplicationController
  def index
  end

  def dashboard
    @comments = Comment.owned_by(current_user).limit(10)
    # TODO We should be smarter here and pull in collections we ar admin for
    @collections = Collection.limit(10).where(:collector_id => current_user)
    @items = Item.limit(10).where(:collector_id => current_user)
  end
end
