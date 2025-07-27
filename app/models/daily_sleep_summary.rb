class DailySleepSummary < ApplicationRecord
  belongs_to :user
  
  validates :date, presence: true
  validates :total_sleep_duration_minutes, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :number_of_sleep_sessions, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :user_id, uniqueness: { scope: :date, message: "already has a summary for this date" }
end
