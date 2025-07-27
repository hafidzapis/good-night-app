class AddIndexesToDailySleepSummaries < ActiveRecord::Migration[7.0]
  def change
    add_index :daily_sleep_summaries, [:user_id, :total_sleep_duration_minutes, :date], 
              name: 'index_daily_sleep_summaries_on_user_duration_date'
  end
end 