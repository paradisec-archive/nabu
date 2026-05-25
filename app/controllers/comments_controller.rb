class CommentsController < ApplicationController
  COMMENTABLE_TYPES = { 'Item' => Item }.freeze

  load_and_authorize_resource except: :create

  def index
    @comments = @comments.page(params[:page])
  end

  def create
    klass = COMMENTABLE_TYPES[params[:commentable_type]]
    raise ActionController::BadRequest, 'Invalid commentable_type' unless klass

    resource = klass.find(params[:commentable_id])
    @comment = resource.comments.build(comment_params)
    authorize! :create, @comment
    @comment.owner = current_user
    if @comment.save
      flash[:notice] = 'Comment sent successfully.'
    else
      flash[:error] = 'Error while sending the comment.'
    end

    redirect_to [@comment.commentable.collection, @comment.commentable]
  end

  def destroy
    @comment.destroy
    flash[:notice] = 'Comment removed successfully.'

    respond_with @comment
  end

  def spam
    @comment.status = 'spam'
    @comment.save!
    flash[:notice] = 'Comment marked as spam.'
    redirect_to root_path
  end

  def approve
    @comment.status = 'approved'
    @comment.save!
    flash[:notice] = 'Comment approved.'
    redirect_to root_path
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
