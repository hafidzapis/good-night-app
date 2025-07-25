class CreateDailySleepSummaries < ActiveRecord::Migration[7.1]
  def change
    create_table :daily_sleep_summaries do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date
      t.integer :total_sleep_duration_minutes
      t.integer :number_of_sleep_sessions

      t.timestamps
    end
    add_index :daily_sleep_summaries, [:user_id, :date], unique: true, name: 'index_daily_sleep_summaries_on_user_id_and_date'
  end
end
