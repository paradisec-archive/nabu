class EssencesController < ApplicationController
  before_action :find_essence, only: %i[show]
  load_and_authorize_resource :collection, find_by: :identifier, except: [:list_mimetypes]
  load_and_authorize_resource :item, find_by: :identifier, through: :collection, except: [:list_mimetypes]
  load_and_authorize_resource :essence, through: :item, except: [:list_mimetypes]

  rescue_from CanCan::AccessDenied do
    flash[:notice] = 'Please Sign Up and Log In to access this file.'
    redirect_to new_user_session_path
  end

  def show
    @page_title = "Nabu - #{@essence.filename} (#{@essence.item.title})"

    return if can? :manage, @essence

    if @essence.item.access_condition.nil?
      flash[:error] = 'Item does not have data access conditions set'
      redirect_to [@collection, @item]
    elsif ['Open (subject to agreeing to PDSC access conditions)'].include? @essence.item.access_condition.name
      redirect_to show_terms_collection_item_essence_path unless session["terms_#{@collection.id}"] == true
    end
  end

  def download
    if !@current_user.admin? && @essence.is_archived?
      flash[:error] = 'This file is archived and can only be downloaded by admins'
      redirect_to [@collection, @item, @essence]

      return
    end

    Download.create! user: current_user, essence: @essence

    location = Nabu::Catalog.instance.essence_url(@essence, filename: @essence.filename, as_attachment: true)
    raise ActionController::RoutingError, 'Essence file not found' unless location

    redirect_to location, allow_other_host: true
  end

  def display
    if !@current_user.admin? && @essence.is_archived?
      flash[:error] = 'This file is archived and can only be displayed to admins'
      redirect_to [@collection, @item, @essence]

      return
    end

    location = Nabu::Catalog.instance.essence_url(@essence)
    raise ActionController::RoutingError, 'Essence file not found' unless location

    redirect_to location, allow_other_host: true
  end

  def show_terms
    @page_title = 'Nabu - Terms and Conditions'
  end

  def agree_to_terms
    if params[:agree] == '1'
      session["terms_#{@collection.id}"] = true
      redirect_to [@collection, @item, @essence]
    else
      flash[:error] = 'You must agree to the PDSC access form before you can view files'
      redirect_to [@collection, @item]
    end
  end

  def destroy
    item = @essence.item
    response = EssenceDestructionService.destroy(@essence)
    flash[response.keys.first] = response.values.first # there's only one pair
    redirect_to [item.collection, item]
  end

  def list_mimetypes
    # list distinct mimetypes from the db
    render json: { results: Essence.where('mimetype like ?', "%#{params[:q]}%").distinct.order(:mimetype).pluck(:mimetype).map { |m| { id: m, text: m } } }
  end

  def essence_params
    params.require(:essence)
          .permit(:item, :item_id, :filename, :mimetype, :bitrate, :samplerate, :size, :duration, :channels, :fps, :derived_files_generated)
  end


  def find_essence
    @essence = Essence.includes(item: { item_agents: %i[agent_role user] }).find(params[:id])
  end
end
