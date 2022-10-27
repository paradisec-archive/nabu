class CommentMailer < ApplicationMailer
  def comment_email(comment)
    @comment = comment
    @resource = case @comment.commentable.class.to_s
    when 'Collection' then [@comment.commentable]
    when 'Item' then [@comment.commentable.collection, @comment.commentable]
    when 'Essence' then [@comment.commentable.item.collection, @comment.commentable.item, @comment.commentable]
    else
      raise "Don't know URL for resource #{@comment.commentable.class}"
    end

    mail(subject: "[nabu] New comment posted by #{@comment.owner_name}")
  end
end
