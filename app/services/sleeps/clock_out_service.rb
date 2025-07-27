module Sleeps
  class ClockOutService
    extend Dry::Initializer
    option :user
    option :sleep_record_id

    def call!
      sleep_record = user.sleeps.find_by(id: sleep_record_id)

      return Result.failure('Sleep record not found') unless sleep_record
      return Result.failure('Sleep record has already been clocked out') if sleep_record.clock_out_time.present?

      sleep_record.clock_out_time = Time.zone.now
      
      if sleep_record.save
        Result.success(sleep_record)
      else
        Result.failure(sleep_record.errors.full_messages)
      end
    end
  end
end 