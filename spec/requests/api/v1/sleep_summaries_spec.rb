require 'rails_helper'

RSpec.describe 'Sleep Summaries API', type: :request do
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => user.name } }

  describe 'GET /api/v1/sleep_summaries' do
    context 'with default date range' do
      let!(:summary1) { create(:daily_sleep_summary, user: user, date: 3.days.ago.to_date, total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }
      let!(:summary2) { create(:daily_sleep_summary, user: user, date: 1.day.ago.to_date, total_sleep_duration_minutes: 360, number_of_sleep_sessions: 1) }

      it 'returns sleep summary for the last 7 days with sorted breakdown' do
        get '/api/v1/sleep_summaries', headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['period']['start_date']).to eq(7.days.ago.to_date.to_s)
          expect(json_response['period']['end_date']).to eq(1.day.ago.to_date.to_s)

          summary = json_response['summary']
          expect(summary['total_sleep_duration_minutes']).to eq(840)
          expect(summary['total_sleep_duration_hours']).to eq(14.0)
          expect(summary['total_number_of_sleep_sessions']).to eq(2)
          expect(summary['average_sleep_duration_minutes']).to eq(420.0)
          expect(summary['average_sleep_duration_hours']).to eq(7.0)
          expect(summary['average_sleep_sessions_per_day']).to eq(1.0)
          expect(summary['days_with_sleep']).to eq(2)
          expect(summary['total_days']).to eq(2)
          expect(summary['sleep_efficiency_percentage']).to eq(100.0)

          expect(json_response['daily_breakdown'].length).to eq(2)
          expect(json_response['daily_breakdown'].first['total_sleep_duration_minutes']).to eq(480)
          expect(json_response['daily_breakdown'].first['date']).to eq(3.days.ago.to_date.to_s)
          expect(json_response['daily_breakdown'].second['total_sleep_duration_minutes']).to eq(360)
          expect(json_response['daily_breakdown'].second['date']).to eq(1.day.ago.to_date.to_s)

          pagination = json_response['pagination']
          expect(pagination['current_page']).to eq(1)
          expect(pagination['per_page']).to eq(25)
          expect(pagination['total_count']).to eq(2)
          expect(pagination['total_pages']).to eq(1)
          expect(pagination['has_next_page']).to be false
          expect(pagination['has_prev_page']).to be false
        end
      end
    end

    context 'with custom date range' do
      let!(:summary1) { create(:daily_sleep_summary, user: user, date: Date.parse('2024-01-01'), total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }
      let!(:summary2) { create(:daily_sleep_summary, user: user, date: Date.parse('2024-01-02'), total_sleep_duration_minutes: 420, number_of_sleep_sessions: 2) }
      let!(:summary3) { create(:daily_sleep_summary, user: user, date: Date.parse('2024-01-03'), total_sleep_duration_minutes: 360, number_of_sleep_sessions: 1) }

      it 'returns sleep summary for specified date range with sorted breakdown' do
        get '/api/v1/sleep_summaries', params: { start_date: '2024-01-01', end_date: '2024-01-03' }, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['period']['start_date']).to eq('2024-01-01')
          expect(json_response['period']['end_date']).to eq('2024-01-03')
          expect(json_response['summary']['total_sleep_duration_minutes']).to eq(1260)

          breakdown = json_response['daily_breakdown']
          expect(breakdown.length).to eq(3)
          expect(breakdown[0]['total_sleep_duration_minutes']).to eq(480)
          expect(breakdown[1]['total_sleep_duration_minutes']).to eq(420)
          expect(breakdown[2]['total_sleep_duration_minutes']).to eq(360)
        end
      end
    end

    context 'with pagination' do
      let!(:summaries) do
        (0..29).map do |i| 
          create(:daily_sleep_summary, 
                 user: user, 
                 date: Date.parse('2024-01-01') + i.days, 
                 total_sleep_duration_minutes: 500 - i,
                 number_of_sleep_sessions: 1)
        end
      end

      it 'returns paginated results' do
        get '/api/v1/sleep_summaries', params: { start_date: '2024-01-01', end_date: '2024-01-30', page: 2, per: 10 }, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['daily_breakdown'].length).to eq(10)
          
          pagination = json_response['pagination']
          expect(pagination['current_page']).to eq(2)
          expect(pagination['per_page']).to eq(10)
          expect(pagination['total_count']).to eq(30)
          expect(pagination['total_pages']).to eq(3)
          expect(pagination['has_next_page']).to be true
          expect(pagination['has_prev_page']).to be true

 
          expect(json_response['daily_breakdown'].first['total_sleep_duration_minutes']).to eq(490)
        end
      end
    end

    context 'with invalid date parameters' do
      it 'falls back to default date range' do
        get '/api/v1/sleep_summaries', params: { start_date: 'invalid-date', end_date: 'also-invalid' }, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['period']['start_date']).to eq(7.days.ago.to_date.to_s)
          expect(json_response['period']['end_date']).to eq(1.day.ago.to_date.to_s)
        end
      end
    end

    context 'with date range too large' do
      it 'returns error for date range exceeding limit' do
        get '/api/v1/sleep_summaries', params: { start_date: '2024-01-01', end_date: '2024-06-01' }, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['error']['error']).to eq('Date range is too long')
        end
      end
    end

    context 'with no sleep data' do
      it 'returns empty statistics' do
        get '/api/v1/sleep_summaries', headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          summary = json_response['summary']
          expect(summary['total_sleep_duration_minutes']).to eq(0)
          expect(summary['total_sleep_duration_hours']).to eq(0)
          expect(summary['total_number_of_sleep_sessions']).to eq(0)
          expect(summary['average_sleep_duration_minutes']).to eq(0)
          expect(summary['average_sleep_duration_hours']).to eq(0)
          expect(summary['average_sleep_sessions_per_day']).to eq(0)
          expect(summary['days_with_sleep']).to eq(0)
          expect(summary['total_days']).to eq(0)
          expect(summary['sleep_efficiency_percentage']).to eq(0)

          expect(json_response['daily_breakdown']).to be_empty
        end
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/sleep_summaries'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with different user data' do
      let(:other_user) { create(:user) }
      let!(:other_summary) { create(:daily_sleep_summary, user: other_user, date: 2.days.ago.to_date, total_sleep_duration_minutes: 600, number_of_sleep_sessions: 1) }

      it 'only returns data for the authenticated user' do
        get '/api/v1/sleep_summaries', headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response['summary']['total_sleep_duration_minutes']).to eq(0)
          expect(json_response['daily_breakdown']).to be_empty
        end
      end
    end

    context 'with same sleep duration on different dates' do
      let!(:summary1) { create(:daily_sleep_summary, user: user, date: Date.parse('2024-01-01'), total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }
      let!(:summary2) { create(:daily_sleep_summary, user: user, date: Date.parse('2024-01-02'), total_sleep_duration_minutes: 480, number_of_sleep_sessions: 1) }

      it 'sorts by date desc when sleep duration is equal' do
        get '/api/v1/sleep_summaries', params: { start_date: '2024-01-01', end_date: '2024-01-02' }, headers: headers

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          breakdown = json_response['daily_breakdown']
          expect(breakdown.length).to eq(2)
          expect(breakdown[0]['date']).to eq('2024-01-02')
          expect(breakdown[1]['date']).to eq('2024-01-01')
          expect(breakdown[0]['total_sleep_duration_minutes']).to eq(480)
          expect(breakdown[1]['total_sleep_duration_minutes']).to eq(480)
        end
      end
    end
  end
end