class UserSleepSummaryJob < ApplicationJob
  queue_as :default

  def perform(user_id, date)
    user = User.find(user_id)
    
    Rails.logger.info "Updating daily summary for user #{user.name} on #{date}"
    
    result = Sleeps::SleepSummaryPopulatorService.new(
      user: user,
      date: date
    ).call!
    
    if result.success?
      Rails.logger.info "Daily summary updated for user #{user.name} on #{date}"
    else
      Rails.logger.error "Failed to update daily summary for user #{user.name}: #{result.error}"
    end
  end
end 