class User < ApplicationRecord
  has_many :sleeps, dependent: :destroy
  has_many :daily_sleep_summaries, dependent: :destroy
  
  # Follow associations
  has_many :follows, foreign_key: :follower_id, class_name: 'Follow', dependent: :destroy
  has_many :followed_users, through: :follows, source: :followed
  
  has_many :reverse_follows, foreign_key: :followed_id, class_name: 'Follow', dependent: :destroy
  has_many :followers, through: :reverse_follows, source: :follower
  
  validates :name, presence: true, length: { maximum: 255 }
end
