require 'rails_helper'

RSpec.describe Sleeps::SleepSummaryService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user: user) }

  describe '#call!' do
    context 'with default date range (last 7 days ending yesterday)' do
      let!(:summary1) { create(:daily_sleep_summary, user: user, date: 3.days.ago.to_date, total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }
      let!(:summary2) { create(:daily_sleep_summary, user: user, date: 2.days.ago.to_date, total_sleep_duration_minutes: 420, number_of_sleep_sessions: 2) }
      let!(:summary3) { create(:daily_sleep_summary, user: user, date: 1.day.ago.to_date, total_sleep_duration_minutes: 360, number_of_sleep_sessions: 1) }

      it 'returns aggregated sleep summary' do
        result = service.call!

        aggregate_failures do
          expect(result.success?).to be true
          data = result.data

          expect(data[:period][:start_date]).to eq(7.days.ago.to_date)
          expect(data[:period][:end_date]).to eq(1.day.ago.to_date)

          summary = data[:summary]
          expect(summary[:total_sleep_duration_minutes]).to eq(1260)
          expect(summary[:total_sleep_duration_hours]).to eq(21.0)
          expect(summary[:total_number_of_sleep_sessions]).to eq(4)
          expect(summary[:average_sleep_duration_minutes]).to eq(420.0)
          expect(summary[:average_sleep_duration_hours]).to eq(7.0)
          expect(summary[:average_sleep_sessions_per_day]).to eq(1.33)
          expect(summary[:days_with_sleep]).to eq(3)
          expect(summary[:total_days]).to eq(3)
          expect(summary[:sleep_efficiency_percentage]).to eq(100.0)

          expect(data[:daily_breakdown].length).to eq(3)
          expect(data[:daily_breakdown].first[:date]).to eq(3.days.ago.to_date)
          expect(data[:daily_breakdown].first[:total_sleep_duration_minutes]).to eq(480)
        end
      end
    end

    context 'with custom date range' do
      let(:start_date) { '2024-01-01' }
      let(:end_date) { '2024-01-03' }
      let(:service) { described_class.new(user: user, start_date: start_date, end_date: end_date) }

      let!(:summary1) { create(:daily_sleep_summary, user: user, date: Date.parse('2024-01-01'), total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }
      let!(:summary2) { create(:daily_sleep_summary, user: user, date: Date.parse('2024-01-02'), total_sleep_duration_minutes: 420, number_of_sleep_sessions: 2) }
      let!(:summary3) { create(:daily_sleep_summary, user: user, date: Date.parse('2024-01-03'), total_sleep_duration_minutes: 360, number_of_sleep_sessions: 1) }

      it 'returns summary for specified date range' do
        result = service.call!

        aggregate_failures do
          expect(result.success?).to be true
          data = result.data

          expect(data[:period][:start_date]).to eq(Date.parse('2024-01-01'))
          expect(data[:period][:end_date]).to eq(Date.parse('2024-01-03'))
          expect(data[:summary][:total_sleep_duration_minutes]).to eq(1260)
        end
      end
    end

    context 'with invalid date parameters' do
      let(:service) { described_class.new(user: user, start_date: 'invalid-date', end_date: 'also-invalid') }

      it 'falls back to default date range' do
        result = service.call!

        aggregate_failures do
          expect(result.success?).to be true
          data = result.data

          expect(data[:period][:start_date]).to eq(7.days.ago.to_date)
          expect(data[:period][:end_date]).to eq(1.day.ago.to_date)
        end
      end
    end

    context 'with no sleep data' do
      it 'returns empty statistics' do
        result = service.call!

        aggregate_failures do
          expect(result.success?).to be true
          data = result.data

          summary = data[:summary]
          expect(summary[:total_sleep_duration_minutes]).to eq(0)
          expect(summary[:total_sleep_duration_hours]).to eq(0)
          expect(summary[:total_number_of_sleep_sessions]).to eq(0)
          expect(summary[:average_sleep_duration_minutes]).to eq(0)
          expect(summary[:average_sleep_duration_hours]).to eq(0)
          expect(summary[:average_sleep_sessions_per_day]).to eq(0)
          expect(summary[:days_with_sleep]).to eq(0)
          expect(summary[:total_days]).to eq(0)
          expect(summary[:sleep_efficiency_percentage]).to eq(0)

          expect(data[:daily_breakdown]).to be_empty
        end
      end
    end

    context 'with partial sleep data (some days with no sleep)' do
      let!(:summary1) { create(:daily_sleep_summary, user: user, date: 3.days.ago.to_date, total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }
      let!(:summary2) { create(:daily_sleep_summary, user: user, date: 1.day.ago.to_date, total_sleep_duration_minutes: 360, number_of_sleep_sessions: 1) }

      it 'calculates sleep efficiency correctly' do
        result = service.call!

        aggregate_failures do
          expect(result.success?).to be true
          data = result.data

          summary = data[:summary]
          expect(summary[:days_with_sleep]).to eq(2)
          expect(summary[:total_days]).to eq(2)
          expect(summary[:sleep_efficiency_percentage]).to eq(100.0)
        end
      end
    end
  end
end 