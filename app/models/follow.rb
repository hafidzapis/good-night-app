class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'
  
  validates :follower_id, presence: true
  validates :followed_id, presence: true
  validates :follower_id, uniqueness: { scope: :followed_id, message: "is already following this user" }
  validate :cannot_follow_self
  
  private
  
  def cannot_follow_self
    if follower_id == followed_id
      errors.add(:base, "Cannot follow yourself")
    end
  end
end
