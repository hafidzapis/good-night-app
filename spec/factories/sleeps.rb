FactoryBot.define do
  factory :sleep do
    user
    clock_in_time { 1.hour.ago }
    clock_out_time { 10.minutes.ago }
    duration_minutes { 10 }

    trait :active do
      clock_out_time { nil }
      duration_minutes { nil }
    end

    trait :completed do
      clock_out_time { clock_in_time + 8.hours }
      duration_minutes { 480 }
    end

    trait :overnight do
      clock_in_time { 1.day.ago.beginning_of_day + 22.hours }
      clock_out_time { 1.day.ago.beginning_of_day + 6.hours + 1.day }
      duration_minutes { 480 }
    end
  end
end 