class VersionsController < ApplicationController
  def revert
    @version = PaperTrail::Version.find(params[:id])

    raise CanCan::AccessDenied unless @version.whodunnit == current_user.id.to_s

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
