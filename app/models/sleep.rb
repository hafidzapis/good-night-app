class Sleep < ApplicationRecord
  belongs_to :user

  MINIMUM_SLEEP_DURATION = 10
  
  validates :clock_in_time, presence: true
  validates :duration_minutes, numericality: { greater_than_or_equal_to: MINIMUM_SLEEP_DURATION, allow_nil: true }
  validate :minimum_sleep_duration
  
  scope :active, -> { where(clock_out_time: nil) }
  scope :completed, -> { where.not(clock_out_time: nil) }
  
  before_save :calculate_duration, if: :clock_out_time_changed?
  
  private
  
  def calculate_duration
    return unless clock_out_time.present? && clock_in_time.present?
    
    self.duration_minutes = ((clock_out_time - clock_in_time) / 60).to_i
  end

  def minimum_sleep_duration
    return unless clock_out_time.present? && clock_in_time.present?
    
    duration = (clock_out_time - clock_in_time) / 60
    if duration < MINIMUM_SLEEP_DURATION
      errors.add(:clock_out_time, "sleep duration must be at least #{MINIMUM_SLEEP_DURATION} minutes")
    end
  end
end
