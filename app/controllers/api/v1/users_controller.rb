module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [:profile]

      def index
        @users = User.page(params[:page]).per(params[:per_page] || 25)
        render render_paginated_collection(@users, :users)
      end

      def profile
        render json: @user
      end

      def create
        @user = User.new(user_params)

        if @user.save
          render json: @user, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def follow
        result = Follows::FollowService.new(follower: current_user, followed_id: params[:id]).call!

        return render render_success('Successfully followed user', :created) if result.success?

        render render_error(result.error)
      end

      def unfollow
        result = Follows::UnfollowService.new(follower: current_user, followed_id: params[:id]).call!
        
        return render render_error(result.error) if result.failure?

        render render_success(nil, :ok)
      end

      def followers
        @followers = current_user.followers
          .select(:id, :name, :created_at)
          .page(params[:page])
          .per(params[:per_page] || 25)
        
        render render_paginated_collection(@followers, :followers)
      end

      def following
        @following = current_user.followed_users
          .select(:id, :name, :created_at)
          .page(params[:page])
          .per(params[:per_page] || 25)
        
        render render_paginated_collection(@following, :following)
      end

      def is_following
        user = User.find(params[:id])
        is_following = current_user.followed_users.include?(user)
        
        render json: { 
          is_following: is_following,
          user_id: user.id,
          user_name: user.name
        }
      rescue ActiveRecord::RecordNotFound
        render render_error('User not found', :not_found)
      end

      private

      def set_user
        @user = current_user
      end

      def user_params
        params.require(:user).permit(:name)
      end
    end
  end
end
