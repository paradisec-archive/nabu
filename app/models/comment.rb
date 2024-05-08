# ## Schema Information
#
# Table name: `comments`
#
# ### Columns
#
# Name                    | Type               | Attributes
# ----------------------- | ------------------ | ---------------------------
# **`id`**                | `integer`          | `not null, primary key`
# **`body`**              | `text(16777215)`   | `not null`
# **`commentable_type`**  | `string(255)`      | `not null`
# **`status`**            | `string(255)`      |
# **`created_at`**        | `datetime`         | `not null`
# **`updated_at`**        | `datetime`         | `not null`
# **`commentable_id`**    | `integer`          | `not null`
# **`owner_id`**          | `integer`          | `not null`
#
# ### Indexes
#
# * `index_comments_on_commentable_id_and_commentable_type`:
#     * **`commentable_id`**
#     * **`commentable_type`**
# * `index_comments_on_owner_id`:
#     * **`owner_id`**
#

class Comment < ApplicationRecord
  has_paper_trail

  paginates_per 5

  belongs_to :commentable, polymorphic: true
  belongs_to :owner, class_name: 'User'

  validates :body, presence: true
  validates :commentable, associated: true
  validates :owner, associated: true

  scope :owned_by, ->(owner) { where(owner_id: owner.id) }
  scope :approved,   -> { where(status: 'approved') }
  scope :unapproved, -> { where(status: 'unapproved') }

  before_save :strip_html_tags
  before_create :moderation
  after_save :send_email

  delegate :name, to: :owner, prefix: true, allow_nil: true

  private

  include ActionView::Helpers::SanitizeHelper
  def strip_html_tags
    self.body = strip_tags(body)
  end

  def moderation
    num_comments = Comment.owned_by(owner).approved.count
    self.status = num_comments.positive? ? 'approved' : 'unapproved'
  end

  def send_email
    CommentMailer.comment_email(self).deliver
  end
end
