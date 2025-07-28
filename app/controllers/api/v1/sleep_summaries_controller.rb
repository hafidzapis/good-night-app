module Api
  module V1
    class SleepSummariesController < BaseController
      def index
        result = Sleeps::SleepSummaryService.new(
          user: current_user,
          start_date: params[:start_date],
          end_date: params[:end_date],
          page: params[:page],
          per: [params[:per]&.to_i || 25, 100].min
        ).call!

        return render json: result.data if result.success?

        render json: { error: result.error }, status: :bad_request
      end
    end
  end
end 