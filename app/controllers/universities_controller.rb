class UniversitiesController < ApplicationController
  load_and_authorize_resource

  def index
    @universities = @universities.order(sort_column + ' ' + sort_direction)
    params.delete(:search) if params[:clear]
    if params[:search]
      match = "%#{params[:search]}%"
      @universities = @universities.where{ name =~ match }
    end

    @universities = @universities.page params[:page]
    @university = University.new
  end

  def create
    @university = University.new params[:university]

    if @university.save
      flash[:notice] = 'University was successfully created.'
      redirect_to :action => :index
    else
      @universities = University.accessible_by(current_ability)
      render :action => :index
    end
  end

  def edit
  end

  def update
    if @university.update_attributes(params[:university])
      flash[:notice] = 'University was successfully updated.'
      redirect_to :action => :index
    else
      render :action => "edit"
    end
  end

  def destroy
    @university.destroy
    flash[:notice] = 'University was deleted.'
    redirect_to :action => :index
  end

  private
  def sort_column
    University.column_names.include?(params[:sort]) ? params[:sort] : "id"
  end

 def sort_direction
   %w[asc desc].include?(params[:direction]) ?  params[:direction] : "asc"
 end
end
