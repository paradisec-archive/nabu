class RepositoryController < ApplicationController
  skip_before_action :authenticate_user!

  def collection
    if params[:edit].present?
      redirect_to edit_collection_url(params[:collection_identifier], host: 'admin-catalog.paradisec.org.au'), status: :found, allow_other_host: true
    else
      redirect_to helpers.oni_collection_url(params[:collection_identifier]), status: :found, allow_other_host: true
    end
  end

  def item
    if params[:edit].present?
      redirect_to edit_collection_item_url(params[:collection_identifier], params[:item_identifier], host: 'admin-catalog.paradisec.org.au'),
                  status: :found, allow_other_host: true
    else
      redirect_to helpers.oni_item_url(params[:collection_identifier], params[:item_identifier]), status: :found, allow_other_host: true
    end
  end

  def essence
    redirect_to helpers.oni_essence_url(params[:collection_identifier], params[:item_identifier], params[:essence_filename]),
                status: :found, allow_other_host: true
  end
end
