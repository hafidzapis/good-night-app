FactoryBot.define do
  factory :daily_sleep_summary do
    user
    date { Date.current }
    total_sleep_duration_minutes { rand(300..600) } # 5-10 hours in minutes
    number_of_sleep_sessions { rand(1..3) }
  end
end 