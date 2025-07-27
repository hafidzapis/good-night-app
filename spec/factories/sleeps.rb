FactoryBot.define do
  factory :sleep do
    association :user
    clock_in_time { Faker::Time.between(from: 1.day.ago, to: Time.zone.now) }
    clock_out_time { Faker::Time.between(from: clock_in_time, to: clock_in_time + 8.hours) }
    duration_minutes { ((clock_out_time - clock_in_time) / 60).to_i }

    trait :active do
      clock_out_time { nil }
      duration_minutes { nil }
    end

    trait :completed do
      clock_out_time { clock_in_time + rand(6..10).hours }
    end
  end
end 