class Comment < ActiveRecord::Base
  has_paper_trail

  paginates_per 5

  attr_accessible :body
  belongs_to :commentable, :polymorphic => true
  belongs_to :owner, :class_name => 'User'

  validates :body, :presence => true
  validates_presence_of :commentable
  validates :owner, :presence => true, :associated => true

  scope :owned_by, lambda {|owner| where('owner_id = ?', owner.id) }
  scope :approved,   where(:status => 'approved')
  scope :unapproved, where(:status => 'unapproved')

  before_save :strip_html_tags
  before_create :moderation
  after_save :send_email


  private
  include ActionView::Helpers::SanitizeHelper
  def strip_html_tags
    self.body = strip_tags(self.body)
  end

  def moderation
    num_comments = Comment.owned_by(owner).approved.count
    if num_comments > 0
      self.status = 'approved'
    else
      self.status = 'unapproved'
    end
  end

  def send_email
    CommentMailer.comment_email(self).deliver
  end

end
