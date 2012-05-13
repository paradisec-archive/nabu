class CommentsController < ApplicationController
  load_and_authorize_resource :except => :create

  respond_to :js

  def create
    resource = params[:commentable_type].constantize.find(params[:commentable_id])
    @comment = resource.comments.build(params[:comment])
    authorize! :create, @comment
    @comment.owner = current_user
    if @comment.save
      flash[:notice] = 'Comment sent successfully.'
    else
      flash[:error] = 'Error while sending the comment.'
    end

    respond_with @comment
  end

  def destroy
    @comment.destroy
    flash[:notice] = 'Comment removed successfully.'

    respond_with @comment
  end

  def spam
    @comment.status = 'spam'
    @comment.save!
    flash[:notice] = 'Comment marked as spam'
    redirect_to root_path
  end

  def approve
    @comment.status = 'approved'
    @comment.save!
    flash[:notice] = 'Comment approved'
    redirect_to root_path
  end
end

