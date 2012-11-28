class EssencesController < ApplicationController
  load_and_authorize_resource :collection, :find_by => :identifier
  load_and_authorize_resource :item, :find_by => :identifier, :through => :collection
  load_and_authorize_resource :essence, :through => :item

  def show
    if @essence.item.access_condition.name == 'Open (subject to agreeing to PDSC access form)'
      if params[:agree].nil?
        redirect_to show_terms_collection_item_essence_path
      elsif params[:agree] == false
        flash[:error] = 'You must agree to the PDSC access form before you can view files'
        redirect_to @item
      end
    elsif @essence.item.access_condition.name == 'Open (subject to the access condition details)'
      if params[:agree].nil?
        redirect_to show_terms_collection_item_essence_path
      elsif params[:agree] == false
        flash[:error] = 'You must agree to the PDSC access form before you can view files'
        redirect_to @item
      end
    end
  end

  def download
    send_file @essence.path, :type => @essence.mimetype, :filename => @essence.filename
  end

  def display
    send_file @essence.path, :disposition => 'inline', :type => @essence.mimetype
  end

  def show_terms
  end

  def agree_to_terms
    redirect_to collection_item_essence_path(:agree => params[:agree])
  end
end
