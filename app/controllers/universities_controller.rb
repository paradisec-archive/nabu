class UniversitiesController < ApplicationController
  load_and_authorize_resource

  respond_to :json

  def create
    @university = University.create params[:university]
    respond_with(@university, :location => '/')
  end

  def university_params
    params.require(:essence)
      .permit(:name, :party_identifier)
  end
end
