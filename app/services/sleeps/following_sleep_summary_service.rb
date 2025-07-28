module Sleeps
  class FollowingSleepSummaryService
    extend Dry::Initializer

    DEFAULT_PER_PAGE = 25
    MAX_PER_PAGE = 100
    LAST_WEEK_DAYS = 7

    option :user
    option :page, optional: true, default: -> { 1 }
    option :per, optional: true, default: -> { DEFAULT_PER_PAGE }

    def call!
              Result.success(
          period: {
            start_date: last_week_start_date.to_s,
            end_date: last_week_end_date.to_s
          },
          friends_summary: build_friends_summary,
          pagination: build_pagination_info
        )
    end

    private

    def last_week_start_date
      @last_week_start_date ||= LAST_WEEK_DAYS.days.ago.to_date
    end

    def last_week_end_date
      @last_week_end_date ||= 1.day.ago.to_date
    end

    def paginated_followed_users
      @paginated_followed_users ||= user.followed_users
                                         .page(page)
                                         .per(per)
    end

    def friends_summary_data
      @friends_summary_data ||= begin
        sql = <<~SQL
          SELECT 
            u.id as user_id,
            u.name as user_name,
            COUNT(ds.*) as total_days,
            COALESCE(SUM(ds.total_sleep_duration_minutes), 0) as total_minutes,
            COALESCE(SUM(ds.number_of_sleep_sessions), 0) as total_sessions,
            COUNT(CASE WHEN ds.total_sleep_duration_minutes > 0 THEN 1 END) as days_with_sleep
          FROM users u
          LEFT JOIN daily_sleep_summaries ds ON u.id = ds.user_id 
            AND ds.date BETWEEN ? AND ?
          WHERE u.id IN (?)
          GROUP BY u.id, u.name
          ORDER BY COALESCE(SUM(ds.total_sleep_duration_minutes), 0) DESC, u.name ASC
        SQL
        
        followed_user_ids = paginated_followed_users.pluck(:id)
        return [] if followed_user_ids.empty?

        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql_array([sql, last_week_start_date, last_week_end_date, followed_user_ids])
        )
      end
    end

    def build_friends_summary
      friends_summary_data.map do |row|
        total_minutes = row['total_minutes'].to_f
        total_days = row['total_days'].to_i
        days_with_sleep = row['days_with_sleep'].to_i

        {
          user_name: row['user_name'],
          user_id: row['user_id'].to_i,
          total_sleep_duration_minutes: total_minutes.to_i,
          total_sleep_duration_hours: (total_minutes / 60).round(2),
          average_sleep_per_day_minutes: total_days.zero? ? 0 : (total_minutes / total_days).round(2),
          average_sleep_per_day_hours: total_days.zero? ? 0 : (total_minutes / total_days / 60).round(2),
          total_number_of_sleep_sessions: row['total_sessions'].to_i,
          average_sleep_sessions_per_day: total_days.zero? ? 0 : (row['total_sessions'].to_f / total_days).round(2),
          days_with_sleep: days_with_sleep,
          total_days: total_days,
          sleep_efficiency_percentage: total_days.zero? ? 0 : ((days_with_sleep.to_f / total_days) * 100).round(2)
        }
      end
    end

    def build_pagination_info
      {
        current_page: paginated_followed_users.current_page,
        per_page: paginated_followed_users.limit_value,
        has_next_page: paginated_followed_users.next_page.present?,
        has_prev_page: paginated_followed_users.prev_page.present?,
        total_count: paginated_followed_users.total_count,
        total_pages: paginated_followed_users.total_pages
      }
    end
  end
end 