class VersionsController < ApplicationController
  def revert
    @version = Version.find(params[:id])
    model = @version.reify
    model.save!
    if model.class == Item
      location = [model.collection, model]
    else
      location = model
    end
    redirect_to location, notice: "Undid #{@version.event}"
  end
end
