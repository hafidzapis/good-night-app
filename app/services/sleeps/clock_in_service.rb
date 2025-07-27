module Sleeps
  class ClockInService
    extend Dry::Initializer
    option :user

    def call!
      return Result.failure('User already has an active sleep record') if user.sleeps.active.first

      sleep_record = user.sleeps.build(clock_in_time: Time.zone.now)
      
      if sleep_record.save
        Result.success(sleep_record: sleep_record)
      else
        Result.failure(sleep_record.errors.full_messages)
      end
    end
  end
end