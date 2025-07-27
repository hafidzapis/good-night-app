module Api
  module V1
    class SleepRecordsController < BaseController
      def clock_in
        result = ::Sleeps::ClockInService.new(user: current_user).call!

        if result.success?
          render json: result.data, status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def clock_out
        result = ::Sleeps::ClockOutService.new(user: current_user, sleep_record_id: params[:id]).call!

        if result.success?
          render json: result.data, status: :ok
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end
    end
  end
end 