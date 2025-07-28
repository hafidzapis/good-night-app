module Api
  module V1
    class FollowingSleepSummariesController < BaseController
      def index
        result = Sleeps::FollowingSleepSummaryService.new(
          user: current_user,
          start_date: params[:start_date],
          end_date: params[:end_date],
          page: params[:page],
          per: [params[:per]&.to_i || 25, 25].min
        ).call!

        return render json: result.data if result.success?

        render json: { error: result.error }, status: :bad_request
      end
    end
  end
end 