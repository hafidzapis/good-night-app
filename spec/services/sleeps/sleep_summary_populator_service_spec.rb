require 'rails_helper'

RSpec.describe Sleeps::SleepSummaryPopulatorService do
  let(:user) { create(:user) }
  let(:date) { Date.current }
  let(:service) { described_class.new(user: user, date: date) }

  describe '#call!' do
    context 'when user has sleep records for the date' do
      let!(:sleep1) { create(:sleep, user: user, clock_in_time: date.beginning_of_day + 10.hours, clock_out_time: date.beginning_of_day + 18.hours, duration_minutes: 480) }
      let!(:sleep2) { create(:sleep, user: user, clock_in_time: date.beginning_of_day + 22.hours, clock_out_time: date.beginning_of_day + 6.hours + 1.day, duration_minutes: 480) }

      it 'creates a daily summary with aggregated data' do
        result = service.call!

        expect(result.success?).to be true
        summary = result.data

        aggregate_failures do
          expect(summary.user).to eq(user)
          expect(summary.date).to eq(date)
          expect(summary.total_sleep_duration_minutes).to eq(960)
          expect(summary.number_of_sleep_sessions).to eq(2)
        end
      end

      it 'updates existing summary if it already exists' do
        existing_summary = create(:daily_sleep_summary, user: user, date: date, total_sleep_duration_minutes: 100, number_of_sleep_sessions: 1)

        result = service.call!

        expect(result.success?).to be true
        summary = result.data

        aggregate_failures do
          expect(summary.id).to eq(existing_summary.id)
          expect(summary.total_sleep_duration_minutes).to eq(960)
          expect(summary.number_of_sleep_sessions).to eq(2)
        end
      end
    end

    context 'when user has incomplete sleep records' do
      let!(:incomplete_sleep) { create(:sleep, user: user, clock_in_time: date.beginning_of_day + 10.hours, clock_out_time: nil) }

      it 'only counts completed sleep records' do
        result = service.call!

        expect(result.success?).to be true
        summary = result.data

        expect(summary.total_sleep_duration_minutes).to eq(0)
        expect(summary.number_of_sleep_sessions).to eq(0)
      end
    end
  end
end 