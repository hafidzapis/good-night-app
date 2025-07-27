module Follows
  class UnfollowService
    extend Dry::Initializer
    option :follower
    option :followed_id

    def call!
      follow = Follow.find_by(follower: follower, followed_id: followed_id)
      return Result.failure("Follow relationship not found") unless follow
      
      follow.destroy
      Result.success(nil)
      
    end
  end
end 