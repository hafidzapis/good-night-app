module Follows
  class FollowService
    extend Dry::Initializer
    option :follower
    option :followed_id

    def call!
      return Result.failure("Cannot follow yourself") if self_follow?
      
      return Result.failure("User not found") unless followed_user

      follow = Follow.new(follower: follower, followed: followed_user)
      follow.save ? Result.success(follow) : Result.failure(follow.errors.full_messages.to_sentence)
    end

    private

    def self_follow?
      follower.id == followed_id.to_i
    end

    def followed_user
      User.find_by(id: followed_id)
    end
  end
end 