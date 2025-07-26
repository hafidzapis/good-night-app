module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [:show]

      def index
        @users = User.page(params[:page]).per(params[:per_page] || 25)
        render json: {
          users: @users,
          meta: {
            current_page: @users.current_page,
            next_page: @users.next_page,
            prev_page: @users.prev_page,
            total_pages: @users.total_pages,
            total_count: @users.total_count
          }
        }
      end

      def show
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

      private

      def set_user
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
      end

      def user_params
        params.require(:user).permit(:name)
      end
    end
  end
end
