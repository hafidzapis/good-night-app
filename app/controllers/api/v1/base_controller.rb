module Api
  module V1
    class BaseController < ApplicationController
      include ApiHelper
      
      before_action :authenticate_user!

      private

      def authenticate_user!
        unless current_user
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end

      def current_user
        @current_user ||= User.find_by(name: user_name_from_header)
      end

      def user_name_from_header
        request.headers['Authorization']
      end
    end
  end
end 