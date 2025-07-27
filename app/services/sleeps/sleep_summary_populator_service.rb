module Sleeps
  class SleepSummaryPopulatorService
    extend Dry::Initializer
    option :user
    option :date, optional: true

    def call!
      target_date = date || Date.current
      
      sleep_records = user.sleeps.completed
                          .where("DATE(clock_in_time) = ?", target_date)

      
      total_duration = sleep_records.sum(&:duration_minutes) || 0
      session_count = sleep_records.count

      
      daily_summary = user.daily_sleep_summaries.find_or_initialize_by(date: target_date)
      
      
      daily_summary.total_sleep_duration_minutes = total_duration
      daily_summary.number_of_sleep_sessions = session_count

      daily_summary.save ? Result.success(daily_summary) : Result.failure(daily_summary.errors.full_messages.join(", "))
    end
  end
end 