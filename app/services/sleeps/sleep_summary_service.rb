module Sleeps
  class SleepSummaryService
    extend Dry::Initializer

    MAX_DAYS_RANGE = 90
    DEFAULT_PER_PAGE = 25
    MAX_PER_PAGE = 100

    option :user
    option :start_date, optional: true
    option :end_date, optional: true
    option :page, optional: true, default: -> { 1 }
    option :per, optional: true, default: -> { DEFAULT_PER_PAGE }

    def call!
      return Result.failure(error: 'Date range is too long') if date_range_too_large?

      Result.success(
        period: {
          start_date: parsed_start_date,
          end_date: parsed_end_date
        },
        summary: build_aggregated_stats,
        daily_breakdown: build_daily_breakdown,
        pagination: build_pagination_info
      )
    end

    private

    def date_range_too_large?
      (parsed_end_date - parsed_start_date) > MAX_DAYS_RANGE
    end

    def parsed_start_date
      @parsed_start_date ||= parse_date(start_date) || default_start_date
    end

    def parsed_end_date
      @parsed_end_date ||= parse_date(end_date) || default_end_date
    end

    def parse_date(value)
      Date.parse(value) if value.present?
    rescue ArgumentError
      nil
    end

    def default_start_date
      7.days.ago.to_date
    end

    def default_end_date
      1.day.ago.to_date
    end

    def summary_stats
      @summary_stats ||= begin
        result = user.daily_sleep_summaries
                     .where(date: parsed_start_date..parsed_end_date)
                     .reorder(nil)
                     .pluck(
                       Arel.sql('COUNT(*)'),
                       Arel.sql('COALESCE(SUM(total_sleep_duration_minutes), 0)'),
                       Arel.sql('COALESCE(SUM(number_of_sleep_sessions), 0)'),
                       Arel.sql("COUNT(CASE WHEN total_sleep_duration_minutes > 0 THEN 1 END)")
                     )
                     .first

        OpenStruct.new(
          total_days: result[0].to_i,
          total_minutes: result[1].to_f,
          total_sessions: result[2].to_i,
          days_with_sleep: result[3].to_i
        )
      end
    end

    def paginated_summaries
      @paginated_summaries ||= user.daily_sleep_summaries
                                   .where(date: parsed_start_date..parsed_end_date)
                                   .order(total_sleep_duration_minutes: :desc, date: :desc)
                                   .page(page)
                                   .per(per)
    end



    def build_daily_breakdown
      paginated_summaries.map do |s|
        {
          date: s.date,
          total_sleep_duration_minutes: s.total_sleep_duration_minutes,
          number_of_sleep_sessions: s.number_of_sleep_sessions
        }
      end
    end

    def build_aggregated_stats
      return empty_stats if summary_stats.nil?

      total_minutes = summary_stats.total_minutes.to_f
      total_sessions = summary_stats.total_sessions.to_i
      total_days = summary_stats.total_days.to_i
      days_with_sleep = summary_stats.days_with_sleep.to_i

      return empty_stats if total_days.zero?

      {
        total_sleep_duration_minutes: total_minutes.to_i,
        total_sleep_duration_hours: (total_minutes / 60).round(2),
        total_number_of_sleep_sessions: total_sessions,
        average_sleep_duration_minutes: (total_minutes / total_days).round(2),
        average_sleep_duration_hours: (total_minutes / total_days / 60).round(2),
        average_sleep_sessions_per_day: (total_sessions.to_f / total_days).round(2),
        days_with_sleep: days_with_sleep,
        total_days: total_days,
        sleep_efficiency_percentage: ((days_with_sleep.to_f / total_days) * 100).round(2)
      }
    end

    def build_pagination_info
      {
        current_page: paginated_summaries.current_page,
        per_page: paginated_summaries.limit_value,
        next_page: paginated_summaries.next_page,
        prev_page: paginated_summaries.prev_page,
        total_count: paginated_summaries.total_count,
        total_pages: paginated_summaries.total_pages
      }
    end

    def empty_stats
      {
        total_sleep_duration_minutes: 0,
        total_sleep_duration_hours: 0,
        total_number_of_sleep_sessions: 0,
        average_sleep_duration_minutes: 0,
        average_sleep_duration_hours: 0,
        average_sleep_sessions_per_day: 0,
        days_with_sleep: 0,
        total_days: 0,
        sleep_efficiency_percentage: 0
      }
    end
  end
end 